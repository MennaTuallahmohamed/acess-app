import 'package:access_track/app_constants.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:access_track/core/modals/models.dart';
import 'package:access_track/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanBarcodeScreen extends StatefulWidget {
  
  final Future<bool> Function(String secretCode) onBarcodeScanned;

  final Future<void> Function(String code) onManualSearch;

  final Future<void> Function({
    required String scannedCode,
    required bool success,
    required int attemptNumber,
    String? reason,
  })? onQrAttemptLogged;

  final List<String> recentScans;

  const ScanBarcodeScreen({
    super.key,
    required this.onBarcodeScanned,
    required this.onManualSearch,
    required this.recentScans,
    this.onQrAttemptLogged,
  });

  @override
  State<ScanBarcodeScreen> createState() => _ScanBarcodeScreenState();
}

class _ScanBarcodeScreenState extends State<ScanBarcodeScreen> {
  final MobileScannerController _scanner = MobileScannerController();
  final TextEditingController _manualCtrl = TextEditingController();

  bool _processing = false;
  bool _torchOn = false;

  int _failedQrAttempts = 0;
  String? _message;

  bool get _manualAllowed => _failedQrAttempts >= 3;

  @override
  void dispose() {
    _scanner.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  String? _extractCode(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();

      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;

    final scannedCode = _extractCode(capture);

    if (scannedCode == null || scannedCode.isEmpty) return;

    setState(() {
      _processing = true;
      _message = null;
    });

    await _scanner.stop();

    bool success = false;
    String? reason;

    try {
      success = await widget.onBarcodeScanned(scannedCode);

      if (success) {
        await widget.onQrAttemptLogged?.call(
          scannedCode: scannedCode,
          success: true,
          attemptNumber: _failedQrAttempts + 1,
          reason: 'QR scan success',
        );

        if (!mounted) return;

        setState(() {
          _processing = false;
          _message = 'تم العثور على الجهاز بنجاح';
        });

        return;
      }

      reason = 'Device not found for this QR code';
    } catch (e) {
      reason = e.toString();
      success = false;
    }

    final nextAttempts = _failedQrAttempts + 1;

    await widget.onQrAttemptLogged?.call(
      scannedCode: scannedCode,
      success: false,
      attemptNumber: nextAttempts,
      reason: reason,
    );

    if (!mounted) return;

    setState(() {
      _failedQrAttempts = nextAttempts;
      _processing = false;

      if (_manualAllowed) {
        _message = 'فشل QR Code ثلاث مرات. تم فتح الإدخال اليدوي الآن.';
      } else {
        _message =
            'لا يوجد جهاز بهذا QR Code. برجاء المحاولة مرة أخرى. المحاولة $_failedQrAttempts من 3';
      }
    });

    await Future.delayed(const Duration(milliseconds: 900));

    if (mounted) {
      await _scanner.start();
    }
  }

  Future<void> _manualSearch() async {
    if (!_manualAllowed) {
      setState(() {
        _message =
            'برجاء استخدام QR Code أولاً. سيتم فتح الإدخال اليدوي بعد 3 محاولات QR فاشلة.';
      });
      return;
    }

    final value = _manualCtrl.text.trim();

    if (value.isEmpty) {
      setState(() {
        _message = 'برجاء إدخال الكود';
      });
      return;
    }

    setState(() {
      _processing = true;
      _message = null;
    });

    try {
      await widget.onManualSearch(value);

      if (!mounted) return;

      setState(() {
        _processing = false;
        _message = 'تم العثور على الجهاز';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _processing = false;
        _message = 'لا يوجد جهاز بهذا الكود';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.scanBarcode,
          style: AppText.h4.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _torchOn ? AppColors.accent : Colors.white54,
              size: 24,
            ),
            onPressed: () {
              _scanner.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _scanner,
                    onDetect: _onDetect,
                  ),
                  _ScanOverlay(),
                  if (_processing)
                    Container(
                      color: Colors.black.withOpacity(0.25),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 16,
                    left: 12,
                    right: 12,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'QR Code مطلوب أولاً — المحاولات الفاشلة: $_failedQrAttempts / 3',
                          textAlign: TextAlign.center,
                          style: AppText.small.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceGrey,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        18,
                        20,
                        bottomInset + 20,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 36,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _QrPolicyCard(
                              failedAttempts: _failedQrAttempts,
                              manualAllowed: _manualAllowed,
                            ),
                            if (_message != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCard,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  _message!,
                                  textAlign: TextAlign.center,
                                  style: AppText.small.copyWith(height: 1.5),
                                ),
                              ),
                            ],
                            if (_manualAllowed) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Divider(color: AppColors.border),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      AppStrings.orManual,
                                      style: AppText.small,
                                    ),
                                  ),
                                  const Expanded(
                                    child: Divider(color: AppColors.border),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'الإدخال اليدوي متاح الآن بعد فشل QR Code ثلاث مرات',
                                style: AppText.bodyMed,
                                textAlign: TextAlign.right,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _manualCtrl,
                                      enabled: !_processing,
                                      textDirection: TextDirection.ltr,
                                      decoration: InputDecoration(
                                        hintText:
                                            'IP / Device Code / Serial / Barcode',
                                        prefixIcon: const Icon(
                                          Icons.keyboard_rounded,
                                          size: 20,
                                          color: AppColors.textHint,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                      ),
                                      onFieldSubmitted: (_) => _manualSearch(),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: AppColors.primary,
                                      ),
                                      onPressed:
                                          _processing ? null : _manualSearch,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _processing ? null : _manualSearch,
                                icon: const Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                ),
                                label: Text(AppStrings.searchDB),
                              ),
                            ] else ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCard,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.lock_outline_rounded,
                                      color: AppColors.textHint,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'الإدخال اليدوي مخفي. برجاء استخدام QR Code أولاً.',
                                        textAlign: TextAlign.right,
                                        style: AppText.small.copyWith(
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (_manualAllowed &&
                                widget.recentScans.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ...widget.recentScans.take(1).map(
                                    (s) => _RecentScanChip(
                                      code: s,
                                      onTap: () async {
                                        _manualCtrl.text = s;
                                        await _manualSearch();
                                      },
                                    ),
                                  ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrPolicyCard extends StatelessWidget {
  final int failedAttempts;
  final bool manualAllowed;

  const _QrPolicyCard({
    required this.failedAttempts,
    required this.manualAllowed,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (3 - failedAttempts).clamp(0, 3);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            manualAllowed
                ? Icons.lock_open_rounded
                : Icons.verified_user_rounded,
            color: manualAllowed ? AppColors.success : AppColors.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              manualAllowed
                  ? 'تم فتح الإدخال اليدوي بعد تسجيل 3 محاولات QR فاشلة.'
                  : 'للدقة والأمان، برجاء استخدام QR Code أولاً. متبقي $remaining محاولة قبل فتح الإدخال اليدوي.',
              textAlign: TextAlign.right,
              style: AppText.small.copyWith(
                height: 1.55,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        ColoredBox(
          color: Colors.black.withOpacity(0.5),
          child: const SizedBox.expand(),
        ),
        Center(
          child: Container(
            width: 260,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: AppColors.accent, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                ..._corners(),
                _ScanLine(),
              ],
            ),
          ),
        ),
        Positioned(
          top: screenHeight * 0.28 + 220,
          left: 0,
          right: 0,
          child: Text(
            AppStrings.pointCamera,
            textAlign: TextAlign.center,
            style: AppText.small.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }

  List<Widget> _corners() {
    const size = 20.0;
    const w = 3.0;
    const c = AppColors.accent;

    return [
      _Corner(
        top: 0,
        left: 0,
        borderTop: w,
        borderLeft: w,
        color: c,
        size: size,
      ),
      _Corner(
        top: 0,
        right: 0,
        borderTop: w,
        borderRight: w,
        color: c,
        size: size,
      ),
      _Corner(
        bottom: 0,
        left: 0,
        borderBottom: w,
        borderLeft: w,
        color: c,
        size: size,
      ),
      _Corner(
        bottom: 0,
        right: 0,
        borderBottom: w,
        borderRight: w,
        color: c,
        size: size,
      ),
    ];
  }
}

class _Corner extends StatelessWidget {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double borderTop;
  final double borderLeft;
  final double borderRight;
  final double borderBottom;
  final double size;
  final Color color;

  const _Corner({
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.borderTop = 0,
    this.borderLeft = 0,
    this.borderRight = 0,
    this.borderBottom = 0,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) => Positioned(
        top: top,
        left: left,
        right: right,
        bottom: bottom,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border(
              top: borderTop > 0
                  ? BorderSide(color: color, width: borderTop)
                  : BorderSide.none,
              left: borderLeft > 0
                  ? BorderSide(color: color, width: borderLeft)
                  : BorderSide.none,
              right: borderRight > 0
                  ? BorderSide(color: color, width: borderRight)
                  : BorderSide.none,
              bottom: borderBottom > 0
                  ? BorderSide(color: color, width: borderBottom)
                  : BorderSide.none,
            ),
          ),
        ),
      );
}

class _ScanLine extends StatefulWidget {
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _anim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Positioned(
          left: 8,
          right: 8,
          top: 8 + _anim.value * 168,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.accent,
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      );
}

class _RecentScanChip extends StatelessWidget {
  final String code;
  final VoidCallback onTap;

  const _RecentScanChip({
    required this.code,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.history_rounded,
                size: 14,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'آخر مسح: $code',
                  overflow: TextOverflow.ellipsis,
                  style: AppText.small,
                ),
              ),
            ],
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════
//  SCREEN 5: DEVICE DETAILS
// ═══════════════════════════════════════════════════════
class DeviceDetailsScreen extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback onStartInspection;
  final VoidCallback onBack;

  const DeviceDetailsScreen({
    super.key,
    required this.device,
    required this.onStartInspection,
    required this.onBack,
  });

  String _formatDate(DateTime? d) {
    if (d == null) return 'لا يوجد';

    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

    return '${months[d.month - 1]} ${d.year}';
  }

  String getDeviceTypeLabel() {
    if ((device.backendDeviceTypeName ?? '').trim().isNotEmpty) {
      return device.backendDeviceTypeName!.trim();
    }

    return device.typeAr;
  }

  String getLocationText() {
    if (device.location.trim().isNotEmpty) {
      return device.location.trim();
    }

    final parts = [
      device.room,
      device.floor,
      device.building,
    ].where((e) => e.trim().isNotEmpty).toList();

    if (parts.isEmpty) return 'لا يوجد';

    return parts.join(' - ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 0,
                backgroundColor: AppColors.primary,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: onBack,
                ),
                title: Text(
                  AppStrings.deviceDetails,
                  style: AppText.h4.copyWith(color: Colors.white),
                ),
                centerTitle: true,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Text(
                              device.code,
                              style: AppText.caption.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DeviceTypeIcon(type: device.type, size: 52),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        device.name,
                                        style: AppText.h4,
                                        softWrap: true,
                                        overflow: TextOverflow.visible,
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          StatusBadge(
                                            label: device.statusAr,
                                            type:
                                                statusFromString(device.status),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceGrey,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              device.brand.isEmpty
                                                  ? 'غير محدد'
                                                  : device.brand,
                                              style: AppText.small.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                      const SizedBox(height: 16),
                      _InfoSection(
                        title: AppStrings.deviceData,
                        icon: Icons.info_outline_rounded,
                        rows: [
                          _InfoRow(AppStrings.deviceType, getDeviceTypeLabel()),
                          _InfoRow(
                            'Serial Number',
                            device.serialNumber.isEmpty
                                ? 'لا يوجد'
                                : device.serialNumber,
                          ),
                          _InfoRow(
                            'Barcode',
                            device.barcode.isEmpty
                                ? 'لا يوجد'
                                : device.barcode,
                          ),
                          _InfoRow(
                            'Model',
                            device.modelNumber.isEmpty
                                ? 'لا يوجد'
                                : device.modelNumber,
                          ),
                          _InfoRow(
                            'IP Address',
                            device.ipAddress.isEmpty
                                ? 'لا يوجد'
                                : device.ipAddress,
                          ),
                          _InfoRow(
                            'Firmware',
                            device.firmware.isEmpty
                                ? 'لا يوجد'
                                : device.firmware,
                          ),
                          _InfoRow(AppStrings.location, getLocationText()),
                        ],
                      ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),
                      const SizedBox(height: 12),
                      _InfoSection(
                        title: AppStrings.maintenanceStatus,
                        icon: Icons.build_circle_outlined,
                        rows: [
                          _InfoRow(
                            AppStrings.lastInspection,
                            _formatDate(device.lastInspectionDate),
                          ),
                          _InfoRow(
                            AppStrings.inspector,
                            device.lastInspectorName ?? 'لا يوجد',
                          ),
                          _InfoRow(
                            'Notes',
                            device.notes.isEmpty ? 'لا يوجد' : device.notes,
                          ),
                        ],
                      ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.1),
                      const SizedBox(height: 12),
                      _MapPlaceholder(
                        building: device.building.isEmpty
                            ? 'الموقع الحالي'
                            : device.building,
                        lat: device.latitude,
                        lng: device.longitude,
                      ).animate(delay: 200.ms).fadeIn(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: onStartInspection,
                icon: const Icon(Icons.search_rounded, size: 20),
                label: Text(AppStrings.startInspection),
              ),
            ),
          ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.3),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_InfoRow> rows;

  const _InfoSection({
    required this.title,
    required this.icon,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: AppText.h4),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 14),
            ...rows.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: 3,
                      child: Text(
                        r.label,
                        style: AppText.small.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      flex: 5,
                      child: Text(
                        r.value,
                        textAlign: TextAlign.end,
                        softWrap: true,
                        overflow: TextOverflow.visible,
                        style: AppText.bodyMed.copyWith(height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _InfoRow {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);
}

class _MapPlaceholder extends StatelessWidget {
  final String building;
  final double? lat;
  final double? lng;

  const _MapPlaceholder({
    required this.building,
    this.lat,
    this.lng,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.deviceLocation,
                      style: AppText.h4,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 140,
              decoration: const BoxDecoration(
                color: Color(0xFFE8EDF2),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  CustomPaint(
                    painter: _MapGridPainter(),
                    child: const SizedBox.expand(),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxWidth: 220),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            building,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppText.small.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 10,
                          color: AppColors.primary,
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}