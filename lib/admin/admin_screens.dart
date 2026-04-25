import 'package:access_track/admin/admin_widgets.dart';
import 'package:access_track/app_localizations.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:access_track/admin/admin_screens.dart';
import 'package:access_track/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminScanScreen extends StatefulWidget {
  const AdminScanScreen({super.key});

  @override
  State<AdminScanScreen> createState() => _AdminScanScreenState();
}

class _AdminScanScreenState extends State<AdminScanScreen>
    with SingleTickerProviderStateMixin {
  bool _scanning = false;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startScan() {
    setState(() => _scanning = true);
    _pulseCtrl.repeat(reverse: true);
    // Initialize real scanner here
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B5E),
      body: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top bar ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.isAr ? 'ماسح الباركود' : 'Rapid Scanner',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            l.isAr
                                ? 'امسح الأجهزة للوصول السريع'
                                : 'Scan devices for quick access',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 12,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Scanner viewport ────────────────────────
                Center(
                  child: Column(
                    children: [
                      // Instruction text
                      Text(
                        l.isAr
                            ? 'وجّه الكاميرا نحو كود الجهاز'
                            : 'Point camera at device QR code',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          fontFamily: 'Cairo',
                        ),
                      ).animate().fadeIn(delay: 300.ms),

                      const SizedBox(height: 32),

                      // Scanner frame
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow ring
                          AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (_, __) => Container(
                              width: 300 + (_scanning ? _pulseCtrl.value * 20 : 0),
                              height:
                                  300 + (_scanning ? _pulseCtrl.value * 20 : 0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.cyan.withOpacity(
                                      _scanning
                                          ? 0.15 + _pulseCtrl.value * 0.1
                                          : 0.05),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),

                          // Main frame
                          Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                          ),

                          // Corner brackets
                          SizedBox(
                            width: 280,
                            height: 280,
                            child: Stack(
                              children: [
                                _Corner(
                                    top: 0, left: 0,
                                    vertical: true, horizontal: true),
                                _Corner(
                                    top: 0, right: 0,
                                    vertical: true, horizontal: false),
                                _Corner(
                                    bottom: 0, left: 0,
                                    vertical: false, horizontal: true),
                                _Corner(
                                    bottom: 0, right: 0,
                                    vertical: false, horizontal: false),
                              ],
                            ),
                          ),

                          // Scanning line
                          if (_scanning)
                            SizedBox(
                              width: 240,
                              child: AnimatedBuilder(
                                animation: _pulseCtrl,
                                builder: (_, __) => Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.cyan.withOpacity(0.8),
                                        Colors.white,
                                        Colors.cyan.withOpacity(0.8),
                                        Colors.transparent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.cyan.withOpacity(0.4),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .slideY(
                                  begin: -55,
                                  end: 55,
                                  duration: 1500.ms,
                                  curve: Curves.easeInOut,
                                ),

                          // Center icon (when idle)
                          if (!_scanning)
                            Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 80,
                              color: Colors.white.withOpacity(0.12),
                            ),
                        ],
                      ).animate().scale(
                            delay: 200.ms,
                            curve: Curves.easeOutBack,
                          ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // ── Status indicator ────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _scanning
                        ? Colors.cyan.withOpacity(0.12)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _scanning
                          ? Colors.cyan.withOpacity(0.3)
                          : Colors.white.withOpacity(0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _scanning ? Colors.cyan : Colors.white38,
                          shape: BoxShape.circle,
                          boxShadow: _scanning
                              ? [
                                  BoxShadow(
                                    color: Colors.cyan.withOpacity(0.5),
                                    blurRadius: 6,
                                  )
                                ]
                              : [],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _scanning
                            ? (l.isAr ? 'جاري المسح...' : 'Scanning...')
                            : (l.isAr ? 'في انتظار المسح' : 'Ready to scan'),
                        style: TextStyle(
                          color: _scanning ? Colors.cyan : Colors.white60,
                          fontSize: 13,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 24),

                // ── Activate button ─────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: GestureDetector(
                    onTap: _scanning ? null : _startScan,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _scanning
                              ? [
                                  Colors.cyan.shade700,
                                  Colors.teal.shade800
                                ]
                              : [
                                  const Color(0xFF00B4D8),
                                  const Color(0xFF0077B6),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (const Color(0xFF00B4D8)).withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _scanning
                                ? Icons.stop_circle_rounded
                                : Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _scanning
                                ? (l.isAr ? 'جاري التفعيل...' : 'Scanning...')
                                : (l.isAr ? 'تفعيل الكاميرا' : 'Activate Camera'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                ),

                const SizedBox(height: 16),

                // Manual code entry
                TextButton.icon(
                  onPressed: () {
                    // Show manual entry dialog
                    showDialog(
                      context: context,
                      builder: (_) => _ManualEntryDialog(isAr: l.isAr),
                    );
                  },
                  icon: Icon(Icons.keyboard_rounded,
                      size: 16, color: Colors.white.withOpacity(0.5)),
                  label: Text(
                    l.isAr ? 'إدخال الكود يدوياً' : 'Enter code manually',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms),

                const Spacer(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Corner bracket widget ─────────────────────────────────
class _Corner extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final bool vertical;   // top border visible
  final bool horizontal; // left border visible

  const _Corner({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.vertical,
    required this.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          border: Border(
            top: vertical
                ? const BorderSide(color: Color(0xFF00B4D8), width: 3)
                : BorderSide.none,
            bottom: !vertical
                ? const BorderSide(color: Color(0xFF00B4D8), width: 3)
                : BorderSide.none,
            left: horizontal
                ? const BorderSide(color: Color(0xFF00B4D8), width: 3)
                : BorderSide.none,
            right: !horizontal
                ? const BorderSide(color: Color(0xFF00B4D8), width: 3)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft:
                (vertical && horizontal) ? const Radius.circular(6) : Radius.zero,
            topRight:
                (vertical && !horizontal) ? const Radius.circular(6) : Radius.zero,
            bottomLeft:
                (!vertical && horizontal) ? const Radius.circular(6) : Radius.zero,
            bottomRight:
                (!vertical && !horizontal) ? const Radius.circular(6) : Radius.zero,
          ),
        ),
      ),
    );
  }
}

// ── Grid background painter ───────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Manual entry dialog ───────────────────────────────────
class _ManualEntryDialog extends StatefulWidget {
  final bool isAr;
  const _ManualEntryDialog({required this.isAr});

  @override
  State<_ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends State<_ManualEntryDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isAr ? 'إدخال الكود يدوياً' : 'Enter Device Code',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D1B5E),
                  fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDE5FF)),
              ),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D1B5E)),
                decoration: InputDecoration(
                  hintText: widget.isAr ? 'مثل: A60-001' : 'e.g. A60-001',
                  hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontFamily: 'Cairo',
                      fontSize: 13),
                  prefixIcon: const Icon(Icons.qr_code_rounded,
                      color: Color(0xFF1A237E), size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(widget.isAr ? 'إلغاء' : 'Cancel',
                      style: const TextStyle(fontFamily: 'Cairo')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Handle manual code entry
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(widget.isAr ? 'بحث' : 'Search',
                      style: const TextStyle(
                          fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}