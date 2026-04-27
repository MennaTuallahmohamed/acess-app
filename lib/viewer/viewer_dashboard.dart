import 'package:access_track/admin/admin_devices_screen.dart';
import 'package:access_track/admin/admin_location_screen.dart';
import 'package:access_track/admin/admin_models.dart';
import 'package:access_track/admin/admin_providers.dart';
import 'package:access_track/app_localizations.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:access_track/core/widgets/widgets.dart';
import 'package:access_track/viewer/viewer_inspection_info_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final l = AppLocalizations.of(context);

    final statsAsync = ref.watch(adminStatsProvider);
    final tasksAsync = ref.watch(allTasksProvider);
    final devicesAsync = ref.watch(adminDevicesProvider(null));
    final inspectionsAsync = ref.watch(monthlyInspectionsProvider);

    void refresh() {
      ref.invalidate(adminStatsProvider);
      ref.invalidate(allTasksProvider);
      ref.invalidate(adminDevicesProvider(null));
      ref.invalidate(monthlyInspectionsProvider);
    }

    final isLoading = statsAsync.isLoading ||
        tasksAsync.isLoading ||
        devicesAsync.isLoading ||
        inspectionsAsync.isLoading;

    final error = statsAsync.error ??
        tasksAsync.error ??
        devicesAsync.error ??
        inspectionsAsync.error;

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async => refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 168,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.primaryDark,
              automaticallyImplyLeading: false,
              actions: [
                _TopActionButton(
                  child: Text(
                    l.isAr ? 'EN' : 'عربي',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () => LanguageController.of(context).toggleLanguage(),
                ),
                _TopActionButton(
                  child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                  onTap: refresh,
                ),
                _TopActionButton(
                  child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                  onTap: onLogout,
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                centerTitle: false,
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.isAr ? 'مركز المتابعة والسيطرة' : 'Monitoring Command Center',
                      style: AppText.h3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.isAr
                          ? 'لوحة الموقف العام ومؤشرات التشغيل'
                          : 'Operational situation board and system indicators',
                      style: AppText.caption.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryDark,
                        AppColors.primary,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -38,
                        top: -28,
                        child: Icon(
                          Icons.radar_rounded,
                          size: 205,
                          color: Colors.white.withOpacity(0.035),
                        ),
                      ),
                      Positioned(
                        left: -28,
                        bottom: -28,
                        child: Icon(
                          Icons.shield_rounded,
                          size: 135,
                          color: Colors.white.withOpacity(0.035),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ViewerError(
                  message: error.toString(),
                  onRetry: refresh,
                ),
              )
            else
              SliverToBoxAdapter(
                child: _ViewerContent(
                  isAr: l.isAr,
                  viewerName: viewerName,
                  stats: statsAsync.valueOrNull,
                  tasks: tasksAsync.valueOrNull ?? const [],
                  devices: devicesAsync.valueOrNull ?? const [],
                  inspections: inspectionsAsync.valueOrNull ?? const [],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ViewerContent extends StatelessWidget {
  final bool isAr;
  final String viewerName;
  final AdminStats? stats;
  final List<TaskModel> tasks;
  final List<AdminDeviceModel> devices;
  final List<InspectionDetail> inspections;

  const _ViewerContent({
    required this.isAr,
    required this.viewerName,
    required this.stats,
    required this.tasks,
    required this.devices,
    required this.inspections,
  });

  @override
  Widget build(BuildContext context) {
    final summary = _ViewerSummary.from(
      stats: stats,
      tasks: tasks,
      devices: devices,
      inspections: inspections,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WelcomeHero(
            viewerName: viewerName,
            isAr: isAr,
          ).animate().fadeIn().slideY(begin: 0.08),
          const SizedBox(height: 18),
          _ProfessionalAccessNotice(isAr: isAr)
              .animate(delay: 40.ms)
              .fadeIn()
              .slideY(begin: 0.05),
          const SizedBox(height: 24),
          Text(
            isAr ? 'محاور العرض' : 'Information Sections',
            style: AppText.h4.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          _NavigationGrid(isAr: isAr).animate(delay: 70.ms).fadeIn(),
          const SizedBox(height: 28),
          _CoreStatsGrid(summary: summary, isAr: isAr)
              .animate(delay: 110.ms)
              .fadeIn(),
          const SizedBox(height: 24),
          _InspectionOverviewSection(summary: summary, isAr: isAr)
              .animate(delay: 160.ms)
              .fadeIn()
              .slideY(begin: 0.05),
          const SizedBox(height: 18),
          _DevicesBreakdownSection(summary: summary, isAr: isAr)
              .animate(delay: 210.ms)
              .fadeIn()
              .slideY(begin: 0.05),
          const SizedBox(height: 18),
          _TasksBreakdownSection(summary: summary, isAr: isAr)
              .animate(delay: 260.ms)
              .fadeIn()
              .slideY(begin: 0.05),
          const SizedBox(height: 18),
          _InformationAnalysisSection(summary: summary, isAr: isAr)
              .animate(delay: 310.ms)
              .fadeIn()
              .slideY(begin: 0.05),
        ],
      ),
    );
  }
}

class _ViewerSummary {
  final int totalDevices;
  final int okDevices;
  final int maintenanceDevices;
  final int outDevices;
  final int totalLocations;
  final int totalTasks;
  final int completedTasks;
  final int inProgressTasks;
  final int pendingTasks;
  final int overdueTasks;
  final int urgentTasks;
  final int totalInspections;
  final int inspectionsToday;
  final int okInspections;
  final int notOkInspections;
  final int partialInspections;
  final int unreachableInspections;
  final int inspectionsWithNotes;

  const _ViewerSummary({
    required this.totalDevices,
    required this.okDevices,
    required this.maintenanceDevices,
    required this.outDevices,
    required this.totalLocations,
    required this.totalTasks,
    required this.completedTasks,
    required this.inProgressTasks,
    required this.pendingTasks,
    required this.overdueTasks,
    required this.urgentTasks,
    required this.totalInspections,
    required this.inspectionsToday,
    required this.okInspections,
    required this.notOkInspections,
    required this.partialInspections,
    required this.unreachableInspections,
    required this.inspectionsWithNotes,
  });

  factory _ViewerSummary.from({
    required AdminStats? stats,
    required List<TaskModel> tasks,
    required List<AdminDeviceModel> devices,
    required List<InspectionDetail> inspections,
  }) {
    int taskCount(String s) => tasks.where((e) => e.status.toUpperCase() == s).length;
    int inspectionCount(String s) => inspections.where((e) => e.inspectionStatus.toUpperCase() == s).length;

    final now = DateTime.now();
    final today = inspections.where((e) {
      final d = e.inspectedAt;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).length;

    final notes = inspections.where((e) {
      return (e.notes ?? '').trim().isNotEmpty ||
          (e.issueReason ?? '').trim().isNotEmpty;
    }).length;

    final okDev = devices.where((e) => _isOkDevice(e.currentStatus)).length;
    final maint = devices.where((e) => _isMaintenanceDevice(e.currentStatus)).length;
    final out = devices.where((e) => _isFaultDevice(e.currentStatus)).length;

    final urgent = tasks.where((t) {
      return t.isUrgent ||
          t.isEmergency ||
          t.priority.toUpperCase() == 'URGENT' ||
          t.status.toUpperCase() == 'URGENT';
    }).length;

    return _ViewerSummary(
      totalDevices: devices.isNotEmpty ? devices.length : (stats?.totalDevices ?? 0),
      okDevices: devices.isNotEmpty ? okDev : (stats?.okDevices ?? 0),
      maintenanceDevices: devices.isNotEmpty ? maint : (stats?.maintenanceDevices ?? 0),
      outDevices: devices.isNotEmpty ? out : (stats?.outOfServiceDevices ?? 0),
      totalLocations: stats?.totalLocations ?? 0,
      totalTasks: tasks.isNotEmpty ? tasks.length : (stats?.totalTasks ?? 0),
      completedTasks: tasks.isNotEmpty ? taskCount('COMPLETED') : (stats?.completedTasks ?? 0),
      inProgressTasks: tasks.isNotEmpty ? taskCount('IN_PROGRESS') : (stats?.inProgressTasks ?? 0),
      pendingTasks: tasks.isNotEmpty ? taskCount('PENDING') : (stats?.pendingTasks ?? 0),
      overdueTasks: tasks.isNotEmpty ? taskCount('OVERDUE') : (stats?.overdueTasks ?? 0),
      urgentTasks: tasks.isNotEmpty ? urgent : (stats?.urgentTasks ?? 0),
      totalInspections: inspections.isNotEmpty ? inspections.length : (stats?.totalInspectionsMonth ?? 0),
      inspectionsToday: inspections.isNotEmpty ? today : (stats?.totalInspectionsToday ?? 0),
      okInspections: inspectionCount('OK'),
      notOkInspections: inspectionCount('NOT_OK'),
      partialInspections: inspectionCount('PARTIAL'),
      unreachableInspections: inspectionCount('NOT_REACHABLE'),
      inspectionsWithNotes: notes,
    );
  }

  double get deviceHealthRate => totalDevices == 0 ? 0 : okDevices / totalDevices;
  double get taskCompletionRate => totalTasks == 0 ? 0 : completedTasks / totalTasks;
  double get inspectionOkRate => totalInspections == 0 ? 0 : okInspections / totalInspections;
  int get overallReadiness => ((deviceHealthRate + taskCompletionRate + inspectionOkRate) / 3 * 100).round();
}

class _TopActionButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TopActionButton({
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.11),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  final String viewerName;
  final bool isAr;

  const _WelcomeHero({
    required this.viewerName,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.09),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'حساب متابعة معتمد' : 'Authorized Monitoring Account',
                  style: AppText.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  viewerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.h3.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isAr
                      ? 'واجهة مخصصة لعرض مؤشرات التشغيل والموقف العام دون تنفيذ أوامر إدارية.'
                      : 'Interface dedicated to operational indicators and situation awareness without administrative actions.',
                  style: AppText.caption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
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

class _ProfessionalAccessNotice extends StatelessWidget {
  final bool isAr;

  const _ProfessionalAccessNotice({required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.info.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.policy_rounded, color: AppColors.info, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isAr
                  ? 'يتم عرض بيانات تشغيلية ومؤشرات موقف فقط، مع حجب بيانات الأفراد وأي وظائف تعديل أو إنشاء.'
                  : 'Operational indicators and situation data are displayed only; personnel data and modification functions are withheld.',
              style: AppText.caption.copyWith(
                color: AppColors.info,
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationGrid extends StatelessWidget {
  final bool isAr;

  const _NavigationGrid({required this.isAr});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 720
            ? (constraints.maxWidth - 36) / 4
            : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _NavIconCard(
              width: width,
              title: isAr ? 'الأجهزة' : 'Devices',
              subtitle: isAr ? 'بيانات الأجهزة' : 'Device data',
              icon: Icons.important_devices_rounded,
              color: AppColors.primary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminDevicesScreen(isViewer: true),
                  ),
                );
              },
            ),
            _NavIconCard(
              width: width,
              title: isAr ? 'المواقع' : 'Locations',
              subtitle: isAr ? 'توزيع المواقع' : 'Site distribution',
              icon: Icons.share_location_rounded,
              color: AppColors.accent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminLocationScreen(),
                  ),
                );
              },
            ),
            _NavIconCard(
              width: width,
              title: isAr ? 'التفتيش' : 'Inspections',
              subtitle: isAr ? 'معلومات التفتيش' : 'Inspection status',
              icon: Icons.fact_check_rounded,
              color: Colors.blueAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ViewerInspectionInfoScreen(),
                  ),
                );
              },
            ),
            _NavIconCard(
              width: width,
              title: isAr ? 'تحليل المعلومات' : 'Information Analysis',
              subtitle: isAr ? 'مؤشرات عامة' : 'General indicators',
              icon: Icons.insights_rounded,
              color: AppColors.info,
              onTap: () {
                Scrollable.ensureVisible(
                  context,
                  duration: const Duration(milliseconds: 300),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _NavIconCard extends StatelessWidget {
  final double width;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NavIconCard({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.18)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(icon, size: 34, color: color),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppText.small.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoreStatsGrid extends StatelessWidget {
  final _ViewerSummary summary;
  final bool isAr;

  const _CoreStatsGrid({
    required this.summary,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 720
            ? (constraints.maxWidth - 36) / 4
            : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(
              width: width,
              title: isAr ? 'جاهزية عامة' : 'Readiness',
              value: '${summary.overallReadiness}%',
              icon: Icons.speed_rounded,
              gradient: const [Color(0xFF0F766E), Color(0xFF14B8A6)],
            ),
            _StatCard(
              width: width,
              title: isAr ? 'إجمالي الأجهزة' : 'Total Devices',
              value: summary.totalDevices.toString(),
              icon: Icons.memory_rounded,
              gradient: const [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
            ),
            _StatCard(
              width: width,
              title: isAr ? 'المهام' : 'Tasks',
              value: summary.totalTasks.toString(),
              icon: Icons.assignment_rounded,
              gradient: const [Color(0xFF7C3AED), Color(0xFFA78BFA)],
            ),
            _StatCard(
              width: width,
              title: isAr ? 'التفتيشات' : 'Inspections',
              value: summary.totalInspections.toString(),
              icon: Icons.fact_check_rounded,
              gradient: const [Color(0xFF0284C7), Color(0xFF38BDF8)],
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _StatCard({
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.22),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: AppText.h2.copyWith(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.small.copyWith(
                color: Colors.white.withOpacity(0.82),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InspectionOverviewSection extends StatelessWidget {
  final _ViewerSummary summary;
  final bool isAr;

  const _InspectionOverviewSection({
    required this.summary,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.fact_check_rounded,
      iconColor: Colors.blueAccent,
      title: isAr ? 'معلومات التفتيش' : 'Inspection Information',
      subtitle: isAr
          ? 'موقف التفتيشات ونتائجها دون عرض بيانات الأفراد'
          : 'Inspection status and results without personnel data',
      children: [
        Row(
          children: [
            Expanded(child: _InfoNumber(label: isAr ? 'اليوم' : 'Today', value: summary.inspectionsToday, color: AppColors.primary)),
            const SizedBox(width: 10),
            Expanded(child: _InfoNumber(label: isAr ? 'إجمالي' : 'Total', value: summary.totalInspections, color: Colors.blueAccent)),
            const SizedBox(width: 10),
            Expanded(child: _InfoNumber(label: isAr ? 'بملاحظات' : 'With Notes', value: summary.inspectionsWithNotes, color: AppColors.warning)),
          ],
        ),
        const SizedBox(height: 16),
        _MetricRow(
          label: isAr ? 'نتائج سليمة' : 'OK Results',
          value: summary.okInspections,
          total: summary.totalInspections,
          color: AppColors.success,
        ),
        _MetricRow(
          label: isAr ? 'نتائج غير سليمة' : 'Not OK Results',
          value: summary.notOkInspections,
          total: summary.totalInspections,
          color: AppColors.error,
        ),
        _MetricRow(
          label: isAr ? 'نتائج جزئية أو غير متاحة' : 'Partial / Unreachable',
          value: summary.partialInspections + summary.unreachableInspections,
          total: summary.totalInspections,
          color: AppColors.warning,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ViewerInspectionInfoScreen(),
                ),
              );
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text(isAr ? 'فتح سجل التفتيش' : 'Open Inspection Register'),
          ),
        ),
      ],
    );
  }
}

class _DevicesBreakdownSection extends StatelessWidget {
  final _ViewerSummary summary;
  final bool isAr;

  const _DevicesBreakdownSection({
    required this.summary,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.dvr_rounded,
      iconColor: AppColors.info,
      title: isAr ? 'تحليل حالة الأجهزة' : 'Device Status Summary',
      subtitle: isAr ? 'مؤشرات حالة الأصول المسجلة' : 'Registered asset status indicators',
      children: [
        _MetricRow(label: isAr ? 'أجهزة سليمة' : 'Healthy Devices', value: summary.okDevices, total: summary.totalDevices, color: AppColors.success),
        _MetricRow(label: isAr ? 'تحتاج صيانة' : 'Need Maintenance', value: summary.maintenanceDevices, total: summary.totalDevices, color: AppColors.warning),
        _MetricRow(label: isAr ? 'خارج الخدمة' : 'Out of Service', value: summary.outDevices, total: summary.totalDevices, color: AppColors.error),
      ],
    );
  }
}

class _TasksBreakdownSection extends StatelessWidget {
  final _ViewerSummary summary;
  final bool isAr;

  const _TasksBreakdownSection({
    required this.summary,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.checklist_rtl_rounded,
      iconColor: Colors.purple,
      title: isAr ? 'مؤشرات المهام' : 'Task Indicators',
      subtitle: isAr ? 'أرقام تشغيلية عامة دون أسماء فنيين' : 'Operational figures without technician names',
      children: [
        _MetricRow(label: isAr ? 'مكتملة' : 'Completed', value: summary.completedTasks, total: summary.totalTasks, color: AppColors.success),
        _MetricRow(label: isAr ? 'قيد التنفيذ' : 'In Progress', value: summary.inProgressTasks, total: summary.totalTasks, color: AppColors.info),
        _MetricRow(label: isAr ? 'معلقة' : 'Pending', value: summary.pendingTasks, total: summary.totalTasks, color: Colors.blueGrey),
        if (summary.overdueTasks > 0 || summary.urgentTasks > 0) ...[
          const Divider(height: 26),
          Row(
            children: [
              Expanded(child: _MiniAlertBadge(title: isAr ? 'متأخرة' : 'Overdue', value: summary.overdueTasks, color: Colors.redAccent)),
              const SizedBox(width: 12),
              Expanded(child: _MiniAlertBadge(title: isAr ? 'طارئة' : 'Urgent', value: summary.urgentTasks, color: Colors.deepOrange)),
            ],
          ),
        ],
      ],
    );
  }
}

class _InformationAnalysisSection extends StatelessWidget {
  final _ViewerSummary summary;
  final bool isAr;

  const _InformationAnalysisSection({
    required this.summary,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.analytics_rounded,
      iconColor: AppColors.primary,
      title: isAr ? 'تحليل وعرض المعلومات' : 'Information Analysis',
      subtitle: isAr ? 'ملخص تنفيذي مبني على بيانات النظام الحالية' : 'Executive summary based on current system data',
      children: [
        _InfoLine(
          title: isAr ? 'مؤشر جاهزية الأجهزة' : 'Device readiness indicator',
          value: '${(summary.deviceHealthRate * 100).round()}%',
          color: AppColors.success,
        ),
        const SizedBox(height: 10),
        _InfoLine(
          title: isAr ? 'مؤشر إنجاز المهام' : 'Task completion indicator',
          value: '${(summary.taskCompletionRate * 100).round()}%',
          color: AppColors.info,
        ),
        const SizedBox(height: 10),
        _InfoLine(
          title: isAr ? 'مؤشر سلامة التفتيشات' : 'Inspection OK indicator',
          value: '${(summary.inspectionOkRate * 100).round()}%',
          color: Colors.blueAccent,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary.withOpacity(0.16)),
          ),
          child: Row(
            children: [
              const Icon(Icons.military_tech_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAr
                      ? 'هذه المؤشرات مخصصة لدعم متابعة الموقف العام واتخاذ القرار، ولا تعرض أسماء أو بيانات الأفراد.'
                      : 'These indicators support situation monitoring and decision-making without exposing personnel data.',
                  style: AppText.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.h4.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppText.caption.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          ...children,
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final perc = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppText.bodyMed.copyWith(fontWeight: FontWeight.w800))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$value', style: AppText.caption.copyWith(fontWeight: FontWeight.w900, color: color, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: perc,
              minHeight: 10,
              backgroundColor: AppColors.surfaceGrey,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoNumber extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _InfoNumber({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Column(
        children: [
          Text('$value', style: AppText.h3.copyWith(color: color, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(label, textAlign: TextAlign.center, style: AppText.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _InfoLine({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppText.bodyMed.copyWith(fontWeight: FontWeight.w800))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(value, style: AppText.caption.copyWith(color: color, fontWeight: FontWeight.w900)),
        ),
      ],
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
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 18),
          const SizedBox(width: 7),
          Expanded(child: Text(title, style: AppText.small.copyWith(color: color, fontWeight: FontWeight.w800))),
          Text('$value', style: AppText.h4.copyWith(color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ViewerError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ViewerError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isAr = AppLocalizations.of(context).isAr;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.errorLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.error.withOpacity(0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 42),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppText.bodyMed.copyWith(color: AppColors.error, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isOkDevice(String s) {
  final n = s.trim().toUpperCase();
  return n == 'OK' || n == 'GOOD' || n == 'HEALTHY';
}

bool _isMaintenanceDevice(String s) {
  final n = s.trim().toUpperCase();
  return n == 'MAINTENANCE' ||
      n == 'NEEDS_MAINTENANCE' ||
      n == 'UNDER_MAINTENANCE' ||
      n == 'PARTIAL';
}

bool _isFaultDevice(String s) {
  final n = s.trim().toUpperCase();
  return n == 'OUT_OF_SERVICE' ||
      n == 'NOT_OK' ||
      n == 'NOT_REACHABLE' ||
      n == 'FAULTY';
}
