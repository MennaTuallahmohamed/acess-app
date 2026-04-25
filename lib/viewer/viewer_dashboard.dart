import 'package:access_track/admin/admin_models.dart';
import 'package:access_track/admin/admin_providers.dart';
import 'package:access_track/admin/admin_widgets.dart';
import 'package:access_track/admin/admin_filter_sheet.dart';
import 'package:access_track/admin/admin_devices_screen.dart';
import 'package:access_track/admin/admin_tasks_screen.dart';
import 'package:access_track/admin/admin_location_screen.dart';
import 'package:access_track/admin/admin_analytics_screen.dart';
import 'package:access_track/admin/admin_inspections_screen.dart';
import 'package:access_track/app_constants.dart';
import 'package:access_track/app_localizations.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:access_track/core/widgets/widgets.dart' hide StatCard, SectionHeader, ResponsiveStatGrid;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ════════════════════════════════════════════════════════
//  VIEWER DASHBOARD — COMMAND CENTER (Read-Only)
// ════════════════════════════════════════════════════════
class ViewerDashboardScreen extends ConsumerWidget {
  final String viewerName;
  final VoidCallback onLogout;

  const ViewerDashboardScreen({
    super.key,
    required this.viewerName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l     = AppLocalizations.of(context);
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false, pinned: true,
            backgroundColor: AppColors.primaryDark,
            elevation: 0,
            leading: null,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              centerTitle: false,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.isAr ? 'مركز المراقبة الذكي' : 'Live Command Center', style: AppText.h3.copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                  Text(l.isAr ? 'وضع العرض والمراقبة' : 'Read-Only Monitoring Mode', style: AppText.caption.copyWith(color: AppColors.accent)),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30, top: -20,
                      child: Icon(Icons.satellite_alt_rounded, size: 180, color: Colors.white.withOpacity(0.03)),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Text(
                    l.isAr ? 'EN' : 'عربي',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: () => LanguageController.of(context).toggleLanguage(),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.filter_alt_rounded, color: Colors.white),
                  onPressed: () => AdminFilterSheet.show(context),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: () => ref.invalidate(adminStatsProvider),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white60),
                onPressed: onLogout,
              ),
            ],
          ),

          statsAsync.when(
            data: (s) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome & Core Overview
                    _ViewerWelcomeHero(name: viewerName, l: l).animate().fadeIn().slideY(begin: 0.1),
                    const SizedBox(height: 24),

                    // Quick Navigation Grid
                    Text(l.isAr ? 'روابط سريعة' : 'Quick Navigation', style: AppText.h4.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    _ViewerNavigationGrid(l: l).animate(delay: 50.ms).fadeIn(),
                    
                    const SizedBox(height: 32),

                    // Top Global Stats
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = (constraints.maxWidth - 12) / 2;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _ViewerStatCard(
                              width: width,
                              title: l.isAr ? 'نظام الأجهزة' : 'Asset System',
                              value: s.totalDevices.toString(),
                              icon: Icons.memory_rounded,
                              gradient: const [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
                            ),
                            _ViewerStatCard(
                              width: width,
                              title: l.isAr ? 'البنية التحتية' : 'Infrastructure',
                              value: '${s.totalLocations} ${l.isAr ? "موقع" : "Locs"}',
                              icon: Icons.business_rounded,
                              gradient: const [Color(0xFF009688), Color(0xFF4DB6AC)],
                            ),
                            _ViewerStatCard(
                              width: width,
                              title: l.isAr ? 'رأس المال البشري' : 'Human Capital',
                              value: '${s.activeTechnicians} / ${s.totalTechnicians}',
                              icon: Icons.groups_rounded,
                              gradient: const [Color(0xFFFF9800), Color(0xFFFFB74D)],
                            ),
                            _ViewerStatCard(
                              width: width,
                              title: l.isAr ? 'العمليات' : 'Operations',
                              value: '${s.totalTasks} ${l.isAr ? "مهمة" : "Tasks"}',
                              icon: Icons.assignment_rounded,
                              gradient: const [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                            ),
                          ],
                        );
                      },
                    ).animate(delay: 100.ms).fadeIn(),

                    const SizedBox(height: 32),

                    // Devices Deep Dive
                    _DevicesBreakdownSection(s: s, l: l).animate(delay: 200.ms).fadeIn(),

                    const SizedBox(height: 24),

                    // Tasks deep dive
                    _TasksBreakdownSection(s: s, l: l).animate(delay: 300.ms).fadeIn(),

                    const SizedBox(height: 24),

                    // Inspections deep dive
                    _InspectionsBreakdownSection(s: s, l: l).animate(delay: 400.ms).fadeIn(),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text(e.toString()))),
          ),
        ],
      ),
    );
  }
}

// ── Components ───────────────────────────────────────────

class _ViewerWelcomeHero extends StatelessWidget {
  final String name;
  final AppLocalizations l;

  const _ViewerWelcomeHero({required this.name, required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: l.isAr ? null : -10,
            left: l.isAr ? -10 : null,
            top: -10,
            child: Icon(
              Icons.radar_rounded,
              size: 100,
              color: AppColors.primary.withOpacity(0.04),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.isAr ? 'حساب الاستعراض (دخول آمن)' : 'Viewer Account (Secure Auth)',
                      style: AppText.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: AppText.h3.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ViewerNavigationGrid extends StatelessWidget {
  final AppLocalizations l;
  const _ViewerNavigationGrid({required this.l});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = (constraints.maxWidth - 24) / 3;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _NavIconCard(
            width: width,
            title: l.isAr ? 'الأجهزة' : 'Devices',
            icon: Icons.important_devices_rounded,
            color: AppColors.primary,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDevicesScreen(isViewer: true))),
          ),
          _NavIconCard(
            width: width,
            title: l.isAr ? 'المواقع' : 'Locations',
            icon: Icons.share_location_rounded,
            color: AppColors.accent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLocationScreen())),
          ),
          _NavIconCard(
            width: width,
            title: l.isAr ? 'المهام' : 'Tasks',
            icon: Icons.checklist_rtl_rounded,
            color: Colors.purple,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTasksScreen(isViewer: true))),
          ),
          _NavIconCard(
            width: width,
            title: l.isAr ? 'التفتيش' : 'Inspections',
            icon: Icons.fact_check_rounded,
            color: Colors.blueAccent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminInspectionsScreen())),
          ),
          _NavIconCard(
            width: width,
            title: l.isAr ? 'التحليل' : 'Analytics',
            icon: Icons.analytics_rounded,
            color: AppColors.info,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen())),
          ),
        ],
      );
    });
  }
}

class _NavIconCard extends StatelessWidget {
  final double width;
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NavIconCard({
    required this.width,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 12),
              Text(title, style: AppText.small.copyWith(fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewerStatCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _ViewerStatCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: gradient.first.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: AppText.h2.copyWith(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppText.small.copyWith(color: Colors.white70, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _DevicesBreakdownSection extends StatelessWidget {
  final AdminStats s; final AppLocalizations l;
  const _DevicesBreakdownSection({required this.s, required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.info.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.dvr_rounded, color: AppColors.info, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.isAr ? 'تفاصيل حالة الأجهزة' : 'Asset Health Intelligence', 
                  style: AppText.h4.copyWith(fontWeight: FontWeight.w800)
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _MetricRow(label: l.isAr ? 'أجهزة تعمل بكفاءة' : 'Healthy Operation', value: s.okDevices, total: s.totalDevices, color: AppColors.success),
          _MetricRow(label: l.isAr ? 'أجهزة تحتاج صيانة' : 'Needs Servicing', value: s.maintenanceDevices, total: s.totalDevices, color: AppColors.warning),
          _MetricRow(label: l.isAr ? 'أجهزة معطلة تماماً' : 'Critically Faulty', value: s.outOfServiceDevices, total: s.totalDevices, color: AppColors.error),
        ],
      ),
    );
  }
}

class _TasksBreakdownSection extends StatelessWidget {
  final AdminStats s; final AppLocalizations l;
  const _TasksBreakdownSection({required this.s, required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.checklist_rtl_rounded, color: Colors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.isAr ? 'كفاءة سير المهام' : 'Task Flow Logistics', 
                  style: AppText.h4.copyWith(fontWeight: FontWeight.w800)
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _MetricRow(label: l.isAr ? 'مهمة منجزة' : 'Tasks Completed', value: s.completedTasks, total: s.totalTasks, color: AppColors.success),
          _MetricRow(label: l.isAr ? 'قيد التنفيذ' : 'Work in Progress', value: s.inProgressTasks, total: s.totalTasks, color: AppColors.info),
          _MetricRow(label: l.isAr ? 'مهام معلقة/جديدة' : 'Pending Tasks', value: s.pendingTasks, total: s.totalTasks, color: Colors.blueGrey),
          if (s.overdueTasks > 0 || s.urgentTasks > 0) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _MiniAlertBadge(title: l.isAr ? 'متأخرة' : 'Overdue', value: s.overdueTasks, color: Colors.redAccent)),
                const SizedBox(width: 16),
                Expanded(child: _MiniAlertBadge(title: l.isAr ? 'طارئة جداً' : 'Urgent', value: s.urgentTasks, color: Colors.deepOrange)),
              ],
            ),
          ]
        ],
      ),
    );
  }
}

class _InspectionsBreakdownSection extends StatelessWidget {
  final AdminStats s; final AppLocalizations l;
  const _InspectionsBreakdownSection({required this.s, required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.fact_check_rounded, color: Colors.blueAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.isAr ? 'تحليل التفتيش الميداني' : 'Field Inspection Analytics', 
                  style: AppText.h4.copyWith(fontWeight: FontWeight.w800)
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.isAr ? 'اليوم الحالى' : 'Today\'s Runs', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('${s.totalInspectionsToday}', style: AppText.h2.copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.isAr ? 'هذا الشهر' : 'Month\'s Total', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('${s.totalInspectionsMonth}', style: AppText.h2.copyWith(color: Colors.blueAccent)),
                  ],
                ),
              ),
               Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.isAr ? 'تقارير مفتوحة' : 'Open Reports', style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('${s.openReports}', style: AppText.h2.copyWith(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _MetricRow extends StatelessWidget {
  final String label; final int value; final int total; final Color color;
  const _MetricRow({required this.label, required this.value, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final perc = total == 0 ? 0.0 : (value / total).clamp(0, 1).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppText.bodyMed.copyWith(fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$value', 
                  style: AppText.caption.copyWith(fontWeight: FontWeight.w800, color: color, fontSize: 13)
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
             // Made it slightly thicker for visual emphasis
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: perc,
              minHeight: 12,
              backgroundColor: AppColors.surfaceGrey,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAlertBadge extends StatelessWidget {
  final String title;
  final int value;
  final Color color;

  const _MiniAlertBadge({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Text(title, style: AppText.small.copyWith(color: color, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('$value', style: AppText.h4.copyWith(color: color)),
        ],
      ),
    );
  }
}
