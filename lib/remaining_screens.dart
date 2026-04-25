import 'package:access_track/app_localizations.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:access_track/core/modals/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/widgets/widgets.dart';

// ═══════════════════════════════════════════════════════
//  REPORTS SCREEN — FULL DATA + FILTERS + EXPANDABLE DETAILS
// ═══════════════════════════════════════════════════════
class ReportsScreen extends StatefulWidget {
  final List<ReportModel> reports;
  final Function(ReportModel) onReportTap;

  const ReportsScreen({
    super.key,
    required this.reports,
    required this.onReportTap,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  late TabController _periodTabs;

  String _statusFilter = 'all';
  String _query = '';
  String? _expandedId;

  final _periods = ['all', 'today', 'week', 'month', 'year'];

  @override
  void initState() {
    super.initState();
    _periodTabs = TabController(length: 5, vsync: this);
    _periodTabs.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _periodTabs.dispose();
    super.dispose();
  }

  String get _currentPeriod => _periods[_periodTabs.index];

  List<ReportModel> get _filtered {
    final now = DateTime.now();

    final list = widget.reports.where((r) {
      bool matchPeriod = true;
      switch (_currentPeriod) {
        case 'today':
          matchPeriod = r.createdAt.year == now.year &&
              r.createdAt.month == now.month &&
              r.createdAt.day == now.day;
          break;
        case 'week':
          matchPeriod = now.difference(r.createdAt).inDays <= 7;
          break;
        case 'month':
          matchPeriod =
              r.createdAt.year == now.year && r.createdAt.month == now.month;
          break;
        case 'year':
          matchPeriod = r.createdAt.year == now.year;
          break;
        default:
          matchPeriod = true;
      }

      final matchStatus =
          _statusFilter == 'all' || r.result.trim().toLowerCase() == _statusFilter;

      final q = _query.trim().toLowerCase();
      final matchQ = q.isEmpty ||
          r.deviceName.toLowerCase().contains(q) ||
          r.reportNumber.toLowerCase().contains(q) ||
          r.deviceCode.toLowerCase().contains(q) ||
          r.locationText.toLowerCase().contains(q) ||
          r.inspectorName.toLowerCase().contains(q) ||
          r.notes.toLowerCase().contains(q) ||
          r.deviceType.toLowerCase().contains(q);

      return matchPeriod && matchStatus && matchQ;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return list;
  }

  int _countByResult(String result) {
    return _filtered.where((r) => r.result == result).length;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.reportsLog,
                            style: AppText.h3.copyWith(color: Colors.white),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${filtered.length} ${l.isAr ? 'تقرير' : 'reports'}',
                            style: AppText.small.copyWith(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      textDirection:
                          l.isAr ? TextDirection.rtl : TextDirection.ltr,
                      style: AppText.body,
                      decoration: InputDecoration(
                        hintText: l.searchRpts,
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AppColors.textHint,
                        ),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  size: 18,
                                  color: AppColors.textHint,
                                ),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  TabBar(
                    controller: _periodTabs,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: AppColors.accent,
                    indicatorWeight: 3,
                    labelColor: AppColors.accent,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                    ),
                    tabs: [
                      Tab(text: l.filterAll),
                      Tab(text: l.filterToday),
                      Tab(text: l.filterWeek),
                      Tab(text: l.filterMonth),
                      Tab(text: l.filterYear),
                    ],
                  ),

                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      reverse: l.isAr,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      children: [
                        _Chip(
                          label: l.filterAll,
                          count: filtered.length,
                          value: 'all',
                          current: _statusFilter,
                          onTap: () => setState(() => _statusFilter = 'all'),
                        ),
                        _Chip(
                          label: l.filterGood,
                          count: _countByResult('good'),
                          value: 'good',
                          current: _statusFilter,
                          onTap: () => setState(() => _statusFilter = 'good'),
                        ),
                        _Chip(
                          label: l.filterMaint,
                          count: _countByResult('maintenance') +
                              _countByResult('minor'),
                          value: 'maintenance',
                          current: _statusFilter,
                          onTap: () =>
                              setState(() => _statusFilter = 'maintenance'),
                        ),
                        _Chip(
                          label: l.filterFaulty,
                          count: _countByResult('faulty'),
                          value: 'faulty',
                          current: _statusFilter,
                          onTap: () => setState(() => _statusFilter = 'faulty'),
                        ),
                        _Chip(
                          label: l.isAr ? 'مراجعة' : 'Review',
                          count: _countByResult('review'),
                          value: 'review',
                          current: _statusFilter,
                          onTap: () => setState(() => _statusFilter = 'review'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? _EmptyState(l: l)
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final report = filtered[i];
                      return _ReportExpandableCard(
                        report: report,
                        l: l,
                        isExpanded: _expandedId == report.id,
                        onToggle: () {
                          setState(() {
                            _expandedId =
                                _expandedId == report.id ? null : report.id;
                          });
                        },
                        onOpenFull: () => widget.onReportTap(report),
                      )
                          .animate(delay: Duration(milliseconds: i * 40))
                          .fadeIn(duration: 280.ms)
                          .slideY(begin: 0.05);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final int count;
  final String value;
  final String current;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.count,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sel = current == value;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? AppColors.accent : Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                color: sel ? AppColors.primary : Colors.white70,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: sel ? AppColors.primary : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportExpandableCard extends StatelessWidget {
  final ReportModel report;
  final AppLocalizations l;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onOpenFull;

  const _ReportExpandableCard({
    required this.report,
    required this.l,
    required this.isExpanded,
    required this.onToggle,
    required this.onOpenFull,
  });

  String _timeLabel() {
    final now = DateTime.now();
    final d = report.createdAt;
    final isToday =
        d.day == now.day && d.month == now.month && d.year == now.year;
    final isYesterday = now.difference(d).inDays == 1;
    final hm =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final ap = d.hour < 12 ? (l.isAr ? 'ص' : 'AM') : (l.isAr ? 'م' : 'PM');

    if (isToday) return '${l.todayLbl} $hm $ap';
    if (isYesterday) return '${l.yesterdayLbl} $hm $ap';

    final months = l.isAr
        ? [
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
            'ديسمبر'
          ]
        : [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec'
          ];

    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Color get _resultColor {
    switch (report.result) {
      case 'good':
        return AppColors.success;
      case 'faulty':
        return AppColors.error;
      case 'maintenance':
        return AppColors.warning;
      case 'minor':
        return AppColors.maintenance;
      default:
        return AppColors.info;
    }
  }

  String _extractIssueCode() {
    final match = RegExp(r'Issue Code:\s*(.+)').firstMatch(report.notes);
    return match?.group(1)?.trim() ?? '';
  }

  String _extractIssueTitle() {
    final match = RegExp(r'Issue Title:\s*(.+)').firstMatch(report.notes);
    return match?.group(1)?.trim() ?? '';
  }

  String _extractCompletedSteps() {
    final match = RegExp(r'Completed Steps IDs:\s*(.+)').firstMatch(report.notes);
    return match?.group(1)?.trim() ?? '';
  }

  IconData _deviceIcon(String type) {
    switch (type) {
      case 'computer':
        return Icons.computer_rounded;
      case 'laptop':
        return Icons.laptop_rounded;
      case 'printer':
        return Icons.print_rounded;
      case 'camera':
        return Icons.videocam_rounded;
      case 'access_control':
        return Icons.sensor_door_rounded;
      case 'projector':
        return Icons.cast_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final issueCode = _extractIssueCode();
    final issueTitle = _extractIssueTitle();
    final completedSteps = _extractCompletedSteps();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpanded ? AppColors.accent : AppColors.border,
          width: isExpanded ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _resultColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _resultColor.withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _deviceIcon(report.deviceType),
                      color: _resultColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.deviceName,
                          style: AppText.bodyMed,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceGrey,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            report.deviceCode.isNotEmpty
                                ? report.deviceCode
                                : report.deviceId,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge(
                        label: l.statusLabel(report.result),
                        type: statusFromString(report.result),
                        isSmall: true,
                      ),
                      const SizedBox(height: 5),
                      Text(_timeLabel(), style: AppText.caption),
                    ],
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState:
                isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGrey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        size: 14,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          report.reportNumber,
                          style: AppText.small.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          report.inspectorName,
                          style: AppText.small,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: l.deviceName,
                        value: report.deviceName,
                      ),
                      _DetailRow(
                        label: l.deviceCode,
                        value: report.deviceCode,
                        isCode: true,
                      ),
                      _DetailRow(
                        label: l.inspDate,
                        value:
                            '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}',
                      ),
                      _DetailRow(
                        label: l.inspTime,
                        value:
                            '${report.createdAt.hour.toString().padLeft(2, '0')}:${report.createdAt.minute.toString().padLeft(2, '0')}',
                      ),
                      _DetailRow(
                        label: l.inspector,
                        value: report.inspectorName,
                      ),
                      _DetailRow(
                        label: l.inspLocation,
                        value: report.locationText,
                      ),
                      _DetailRow(
                        label: l.inspResult,
                        value: l.statusLabel(report.result),
                        isStatus: true,
                        statusVal: report.result,
                      ),
                      _DetailRow(
                        label: l.gpsCoords,
                        value:
                            '${report.latitude.toStringAsFixed(4)}°N, ${report.longitude.toStringAsFixed(4)}°E',
                        isCode: true,
                      ),
                      if (issueCode.isNotEmpty)
                        _DetailRow(
                          label: l.isAr ? 'كود المشكلة' : 'Issue Code',
                          value: issueCode,
                          isCode: true,
                        ),
                      if (issueTitle.isNotEmpty)
                        _DetailRow(
                          label: l.isAr ? 'المشكلة' : 'Issue',
                          value: issueTitle,
                        ),
                      if (completedSteps.isNotEmpty)
                        _DetailRow(
                          label: l.isAr ? 'الخطوات المنفذة' : 'Done Steps',
                          value: completedSteps,
                          isCode: true,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                if (report.notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _resultColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border(
                          right: BorderSide(color: _resultColor, width: 3),
                        ),
                      ),
                      child: Text(
                        report.notes,
                        style: AppText.small.copyWith(height: 1.5),
                      ),
                    ),
                  ),

                if (report.imageUrl != null && report.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 90,
                        color: AppColors.surfaceGrey,
                        child: Row(
                          children: const [
                            Expanded(
                              child: Center(
                                child: Icon(
                                  Icons.image_rounded,
                                  size: 32,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 72,
                      child: _MapMini(
                        lat: report.latitude,
                        lng: report.longitude,
                        label: report.building,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          report.floor.isNotEmpty ? report.floor : '—',
                          style: AppText.caption,
                        ),
                      ),
                      GestureDetector(
                        onTap: onOpenFull,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l.isAr ? 'عرض التفاصيل' : 'View Details',
                                style: AppText.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
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
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isCode;
  final bool isStatus;
  final String? statusVal;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isCode = false,
    this.isStatus = false,
    this.statusVal,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: AppText.small),
          ),
          Expanded(
            child: isStatus
                ? Align(
                    alignment: Alignment.centerRight,
                    child: StatusBadge(
                      label: value,
                      type: statusFromString(statusVal ?? ''),
                      isSmall: true,
                    ),
                  )
                : Text(
                    value.isEmpty ? '—' : value,
                    textAlign: TextAlign.end,
                    style: isCode
                        ? const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          )
                        : AppText.bodyMed,
                  ),
          ),
        ],
      ),
    );
  }
}

class _MapMini extends StatelessWidget {
  final double lat;
  final double lng;
  final String label;

  const _MapMini({
    required this.lat,
    required this.lng,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          painter: _GridPainter(),
          child: const SizedBox.expand(),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label.isNotEmpty ? label : '—',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(width: 2, height: 8, color: AppColors.primary),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 4,
          right: 6,
          child: Text(
            '${lat.toStringAsFixed(4)}°N, ${lng.toStringAsFixed(4)}°E',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: AppColors.textHint,
            ),
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFE8EDF2),
    );

    final p = Paint()
      ..color = Colors.grey.withOpacity(0.12)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 14) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l;

  const _EmptyState({required this.l});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 60,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 12),
          Text(
            l.noResults,
            style: AppText.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(l.tryFilter, style: AppText.small),
        ],
      ),
    );
  }
}

class SyncScreen extends StatelessWidget {
  final SyncStatusModel status;
  final VoidCallback onSync;

  const SyncScreen({
    super.key,
    required this.status,
    required this.onSync,
  });

  String _formatLastSync(DateTime? value) {
    if (value == null) return '—';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year;
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hasPending = status.pending > 0 || status.pendingItems.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      appBar: AppBar(
        title: Text(l.navSync),
        centerTitle: true,
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      status.isConnected
                          ? Icons.cloud_done_rounded
                          : Icons.cloud_off_rounded,
                      color: status.isConnected
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        status.isConnected ? l.connected : l.offlineMode,
                        style: AppText.bodyMed,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: onSync,
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: Text(l.syncNow),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _SyncStatCard(
                      label: l.synced,
                      value: status.synced.toString(),
                      color: AppColors.success,
                    ),
                    _SyncStatCard(
                      label: l.pending,
                      value: status.pending.toString(),
                      color: AppColors.warning,
                    ),
                    _SyncStatCard(
                      label: l.failed,
                      value: status.failed.toString(),
                      color: AppColors.error,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${l.isAr ? 'آخر مزامنة' : 'Last sync'}: ${_formatLastSync(status.lastSyncTime)}',
                  style: AppText.small,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(l.pending, style: AppText.bodyMed),
          const SizedBox(height: 10),
          if (!hasPending)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                l.isAr
                    ? 'لا توجد عناصر في انتظار المزامنة'
                    : 'No items waiting to sync.',
              ),
            )
          else
            ...status.pendingItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PendingSyncTile(item: item),
              ),
            ),
        ],
      ),
    );
  }
}

class _SyncStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SyncStatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppText.h3.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppText.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PendingSyncTile extends StatelessWidget {
  final PendingSyncItem item;

  const _PendingSyncTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isFailed ? AppColors.error : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (item.isFailed ? AppColors.error : AppColors.warning)
                .withOpacity(0.12),
            child: Icon(
              item.isFailed ? Icons.error_outline_rounded : Icons.pending_rounded,
              color: item.isFailed ? AppColors.error : AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.deviceName, style: AppText.bodyMed),
                const SizedBox(height: 4),
                Text(
                  item.location.isNotEmpty
                      ? item.location
                      : (l.isAr ? 'موقع غير معروف' : 'Unknown location'),
                  style: AppText.small,
                ),
                const SizedBox(height: 4),
                Text(
                  '${l.isAr ? 'تمت الإضافة' : 'Queued at'} ${item.queuedAt.day.toString().padLeft(2, '0')}/${item.queuedAt.month.toString().padLeft(2, '0')}/${item.queuedAt.year}',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${item.sizeMb.toStringAsFixed(1)} MB',
            style: AppText.caption,
          ),
        ],
      ),
    );
  }
}
