import 'package:access_track/admin/admin_widgets.dart';
import 'package:access_track/app_localizations.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:access_track/admin/admin_screens.dart';
import 'package:access_track/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminScanScreen extends StatelessWidget {
  const AdminScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      appBar: GradientAppBar(
        title: l.isAr ? 'ماسح الباركود السريع' : 'Rapid Scanner',
        subtitle: l.isAr ? 'امسح الأجهزة للوصول السريع' : 'Scan devices for quick access',
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Scanner UI Mockup
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                ),
                // Corner markers
                _buildCorner(Alignment.topLeft),
                _buildCorner(Alignment.topRight),
                _buildCorner(Alignment.bottomLeft),
                _buildCorner(Alignment.bottomRight),
                
                // Scanning Line Animation
                Container(
                  width: 240,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    boxShadow: [
                      BoxShadow(color: AppColors.accent, blurRadius: 10, spreadRadius: 2)
                    ],
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .slideY(begin: -50, end: 50, duration: 1500.ms, curve: Curves.easeInOut),
                
                Icon(Icons.qr_code_scanner_rounded, size: 80, color: AppColors.textHint.withOpacity(0.5)),
              ],
            ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
            
            const SizedBox(height: 48),
            
            Text(
              l.isAr ? 'قم بتوجيه الكاميرا نحو كود الجهاز' : 'Point camera at device QR code',
              style: AppText.bodyMed,
            ).animate().fadeIn(delay: 400.ms),
            
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: () {
                // Initialize scan logic here
              },
              icon: const Icon(Icons.camera_alt_rounded),
              label: Text(l.isAr ? 'تفعيل الكاميرا' : 'Activate Camera'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.primary,
                elevation: 10,
                shadowColor: AppColors.accent.withOpacity(0.5),
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border(
            top: (alignment == Alignment.topLeft || alignment == Alignment.topRight) 
                 ? const BorderSide(color: AppColors.accent, width: 4) : BorderSide.none,
            bottom: (alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight) 
                 ? const BorderSide(color: AppColors.accent, width: 4) : BorderSide.none,
            left: (alignment == Alignment.topLeft || alignment == Alignment.bottomLeft) 
                 ? const BorderSide(color: AppColors.accent, width: 4) : BorderSide.none,
            right: (alignment == Alignment.topRight || alignment == Alignment.bottomRight) 
                 ? const BorderSide(color: AppColors.accent, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
