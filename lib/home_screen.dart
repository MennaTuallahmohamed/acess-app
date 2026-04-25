import 'package:access_track/app_localizations.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:access_track/core/modals/models.dart';
import 'package:access_track/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatelessWidget {
  final UserModel user;
  final TodayStats stats;
  final List<ReportModel> recentReports;
  final VoidCallback onScan;
  final Function(ReportModel) onReportTap;
  final VoidCallback onSeeAllReports;
  final VoidCallback onNotifications;

  const HomeScreen({
    super.key,
    required this.user,
    required this.stats,
    required this.recentReports,
    required this.onScan,
    required this.onReportTap,
    required this.onSeeAllReports,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            snap: true,
            backgroundColor: AppColors.primary,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.appName,
                  style: AppText.h4.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${l.ministry} — ${l.isAr ? "المجمع الوزاري" : "Ministries Complex"}',
                  style: AppText.caption.copyWith(color: Colors.white60),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: onNotifications,
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withOpacity(0.12),
                  child: Text(
                    user.name.length >= 2 ? user.name.substring(0, 2) : user.name,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MinistryGreetingCard(
                    inspectorName: user.name,
                    role: l.roleLabel(user.role),
                    region: user.region,
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08),

                  const SizedBox(height: 28),

                  SectionHeader(
                    title: l.todayStats,
                    icon: Icons.analytics_outlined,
                  ).animate(delay: 100.ms).fadeIn(),

                  const SizedBox(height: 16),

                  ResponsiveStatGrid(
                    cards: [
                      StatCard(
                        icon: Icons.fact_check_rounded,
                        value: stats.totalInspected.toString(),
                        label: l.isAr ? 'إجمالي التفتيشات' : 'Total Inspections',
                        iconColor: AppColors.primary,
                        iconBg: AppColors.infoLight,
                      ),
                      StatCard(
                        icon: Icons.check_circle_rounded,
                        value: stats.good.toString(),
                        label: l.isAr ? 'سليم' : 'Good',
                        iconColor: AppColors.success,
                        iconBg: AppColors.successLight,
                      ),
                      StatCard(
                        icon: Icons.build_circle_rounded,
                        value: stats.needsMaintenance.toString(),
                        label: l.isAr ? 'يحتاج صيانة' : 'Needs Maintenance',
                        iconColor: AppColors.warning,
                        iconBg: AppColors.warningLight,
                      ),
                      StatCard(
                        icon: Icons.rate_review_rounded,
                        value: stats.underReview.toString(),
                        label: l.isAr ? 'تحت المراجعة' : 'Under Review',
                        iconColor: AppColors.error,
                        iconBg: AppColors.errorLight,
                      ),
                    ],
                  ).animate(delay: 180.ms).fadeIn().slideY(begin: 0.05),

                  const SizedBox(height: 32),

                  SectionHeader(
                    title: l.recentInsp,
                    icon: Icons.history_rounded,
                    actionLabel: l.viewAll,
                    onAction: onSeeAllReports,
                  ).animate(delay: 250.ms).fadeIn(),

                  const SizedBox(height: 16),

                  if (recentReports.isEmpty)
                    _EmptyHome(l: l).animate(delay: 300.ms).fadeIn()
                  else
                    ...recentReports.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RecentTile(
                          report: entry.value,
                          l: l,
                          onTap: () => onReportTap(entry.value),
                        )
                            .animate(
                              delay: Duration(milliseconds: 320 + (entry.key * 60)),
                            )
                            .fadeIn(duration: 300.ms)
                            .slideX(begin: 0.04),
                      ),
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onScan,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.qr_code_scanner_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        label: Text(
          l.scanDevice,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ).animate(delay: 450.ms).fadeIn().scale(begin: const Offset(0.85, 0.85)),
    );
  }
}

class _RecentTile extends StatelessWidget {
  final ReportModel report;
  final AppLocalizations l;
  final VoidCallback onTap;

  const _RecentTile({
    required this.report,
    required this.l,
    required this.onTap,
  });

  String _timeLabel() {
    final diff = DateTime.now().difference(report.createdAt);
    if (diff.inMinutes < 60) {
      return l.isAr ? 'منذ ${diff.inMinutes} دقيقة' : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${l.todayLbl} ${report.createdAt.hour}:${report.createdAt.minute.toString().padLeft(2, "0")}';
    }
    return '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            DeviceTypeIcon(type: report.deviceType, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.deviceName,
                    style: AppText.bodyMed.copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.reportNumber,
                    style: AppText.caption.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentDark,
                    ),
                  ),
                  if (report.locationText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 12,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            report.locationText,
                            style: AppText.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
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
                const SizedBox(height: 8),
                Text(
                  _timeLabel(),
                  style: AppText.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  final AppLocalizations l;

  const _EmptyHome({required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_turned_in_outlined,
              size: 48,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l.noInspToday,
            style: AppText.h4.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            l.startScan,
            style: AppText.small,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}