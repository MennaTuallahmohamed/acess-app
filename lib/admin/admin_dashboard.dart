import 'package:access_track/admin/admin_analytics_screen.dart';
import 'package:access_track/admin/admin_models.dart';
import 'package:access_track/admin/admin_providers.dart';
import 'package:access_track/admin/admin_screens.dart';
import 'package:access_track/admin/admin_tasks_screen.dart';
import 'package:access_track/admin/admin_widgets.dart';
import 'package:access_track/app_localizations.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:access_track/core/widgets/widgets.dart'
    hide SectionHeader, ResponsiveStatGrid, StatCard;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminDashboardScreen extends ConsumerWidget {
  final String adminName;
  final VoidCallback onLogout;

  const AdminDashboardScreen({
    super.key,
    required this.adminName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final stats = ref.watch(adminStatsProvider);
    final tasks = ref.watch(allTasksProvider);
    final technicians = ref.watch(techniciansProvider);
    final devices = ref.watch(adminDevicesProvider(null));
    final analytics = ref.watch(adminAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 164,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              onPressed: onLogout,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () {
                  ref.invalidate(adminStatsProvider);
                  ref.invalidate(allTasksProvider);
                  ref.invalidate(techniciansProvider);
                  ref.invalidate(adminDevicesProvider(null));
                  ref.invalidate(adminAnalyticsProvider);
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              centerTitle: false,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.isAr ? 'لوحة المتابعة' : 'Operations Home',
                    style: AppText.h3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    adminName,
                    style: AppText.caption.copyWith(color: Colors.white70),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                child: Stack(
                  children: [
                    Positioned(
                      right: -18,
                      top: -22,
                      child: Icon(
                        Icons.track_changes_rounded,
                        size: 168,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                    Positioned(
                      left: -28,
                      bottom: -24,
                      child: Icon(
                        Icons.auto_graph_rounded,
                        size: 134,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: l.isAr ? 'الملخص العام' : 'General Summary',
                    icon: Icons.insights_rounded,
                  ).animate().fadeIn().slideY(begin: 0.08),
                  const SizedBox(height: 16),
                  stats.when(
                    loading: () => const _StatsShimmer(),
                    error: (e, _) => _ErrorCard(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(adminStatsProvider),
                    ),
                    data: (s) => ResponsiveStatGrid(
                      cards: [
                        StatCard(
                          icon: Icons.people_rounded,
                          value: s.totalTechnicians.toString(),
                          label: l.isAr ? 'الفنيون' : 'Technicians',
                          iconColor: AppColors.primary,
                          iconBg: AppColors.infoLight,
                        ),
                        StatCard(
                          icon: Icons.devices_rounded,
                          value: s.totalDevices.toString(),
                          label: l.isAr ? 'الأجهزة' : 'Devices',
                          iconColor: AppColors.accent,
                          iconBg: AppColors.accent.withOpacity(0.10),
                        ),
                        StatCard(
                          icon: Icons.task_alt_rounded,
                          value: s.completedTasks.toString(),
                          label: l.isAr ? 'المهام المكتملة' : 'Completed Tasks',
                          iconColor: AppColors.success,
                          iconBg: AppColors.successLight,
                        ),
                        StatCard(
                          icon: Icons.assignment_late_rounded,
                          value: s.openReports.toString(),
                          label: l.isAr ? 'التقارير المفتوحة' : 'Open Reports',
                          iconColor: AppColors.warning,
                          iconBg: AppColors.warningLight,
                        ),
                      ],
                    ),
                  ).animate(delay: 80.ms).fadeIn(),
                  const SizedBox(height: 28),
                  SectionHeader(
                    title: l.isAr ? 'نبض التشغيل' : 'Operations Pulse',
                    icon: Icons.motion_photos_on_rounded,
                    actionLabel: l.isAr ? 'كل المهام' : 'All Tasks',
                    onAction: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminTasksScreen()),
                      );
                    },
                  ).animate(delay: 120.ms).fadeIn(),
                  const SizedBox(height: 14),
                  _PulseAsyncBlock(
                    isAr: l.isAr,
                    tasks: tasks,
                    technicians: technicians,
                    devices: devices,
                    onTaskTap: (task) => _openTaskDetail(context, task),
                  ).animate(delay: 180.ms).fadeIn(),
                  const SizedBox(height: 28),
                  SectionHeader(
                    title: l.isAr ? 'التحليلات المتقدمة' : 'Advanced Analytics',
                    icon: Icons.auto_graph_rounded,
                    actionLabel: l.isAr ? 'المزيد' : 'More',
                    onAction: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen()),
                      );
                    },
                  ).animate(delay: 220.ms).fadeIn(),
                  const SizedBox(height: 16),
                  analytics.when(
                    loading: () => const _AnalyticsLoading(),
                    error: (e, _) => _ErrorCard(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(adminAnalyticsProvider),
                    ),
                    data: (a) => Column(
                      children: [
                        _EfficiencyHeroCard(stats: a.stats),
                        const SizedBox(height: 16),
                        AnalyticsChartCard(
                          title: l.isAr ? 'حالة الأجهزة' : 'Device Health Status',
                          subtitle: l.isAr
                              ? 'توزيع حالة الأجهزة الحالية'
                              : 'Current device status distribution',
                          icon: Icons.pie_chart_rounded,
                          child: DeviceStatusDonutChart(data: a.deviceStatus),
                        ).animate(delay: 260.ms).fadeIn().slideY(begin: 0.06),
                        const SizedBox(height: 16),
                        AnalyticsChartCard(
                          title: l.isAr ? 'حالة المهام' : 'Task Status Distribution',
                          subtitle: l.isAr
                              ? 'توزيع المهام حسب الحالة'
                              : 'Tasks grouped by current status',
                          icon: Icons.donut_large_rounded,
                          child: TaskStatusDonutChart(data: a.taskStatus),
                        ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.06),
                        const SizedBox(height: 16),
                        AnalyticsChartCard(
                          title: l.isAr ? 'الأجهزة حسب المباني' : 'Devices by Building',
                          subtitle: l.isAr
                              ? 'أكثر المباني احتواءً على أجهزة'
                              : 'Top buildings by number of devices',
                          icon: Icons.apartment_rounded,
                          child: DevicesByBuildingBarChart(data: a.devicesByBuilding),
                        ).animate(delay: 340.ms).fadeIn().slideY(begin: 0.06),
                        const SizedBox(height: 16),
                        AnalyticsChartCard(
                          title: l.isAr ? 'الأجهزة حسب النوع' : 'Devices by Type',
                          subtitle: l.isAr
                              ? 'توزيع الأجهزة حسب النوع'
                              : 'Device type distribution',
                          icon: Icons.category_rounded,
                          child: DevicesByTypeBarChart(data: a.devicesByType),
                        ).animate(delay: 380.ms).fadeIn().slideY(begin: 0.06),
                        const SizedBox(height: 16),
                        AnalyticsChartCard(
                          title: l.isAr ? 'اتجاه إنجاز المهام' : 'Task Completion Trend',
                          subtitle: l.isAr ? 'آخر 7 أيام' : 'Last 7 days',
                          icon: Icons.show_chart_rounded,
                          child: TaskCompletionTrendChart(data: a.taskCompletionTrend),
                        ).animate(delay: 420.ms).fadeIn().slideY(begin: 0.06),
                        const SizedBox(height: 16),
                        AnalyticsChartCard(
                          title: l.isAr ? 'أداء الفنيين' : 'Technician Performance',
                          subtitle: l.isAr
                              ? 'أفضل الفنيين حسب النشاط'
                              : 'Top technicians by activity',
                          icon: Icons.groups_rounded,
                          child: TechnicianPerformanceBarChart(
                            data: a.technicianPerformance,
                          ),
                        ).animate(delay: 460.ms).fadeIn().slideY(begin: 0.06),
                        const SizedBox(height: 16),
                        AnalyticsChartCard(
                          title: l.isAr ? 'التفتيشات عبر الزمن' : 'Inspections Over Time',
                          subtitle: l.isAr ? 'آخر 7 أيام' : 'Last 7 days',
                          icon: Icons.timeline_rounded,
                          child: InspectionsOverTimeChart(data: a.inspectionsOverTime),
                        ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.06),
                        const SizedBox(height: 16),
                        AnalyticsChartCard(
                          title: l.isAr
                              ? 'تنفيذ المهام لكل فني'
                              : 'Task Execution by Technician',
                          subtitle: l.isAr
                              ? 'مقارنة مكتمل وجارٍ ومعلّق'
                              : 'Completed vs in progress vs pending',
                          icon: Icons.bar_chart_rounded,
                          child: TaskExecutionStackedChart(
                            data: a.taskExecutionByTechnician,
                          ),
                        ).animate(delay: 540.ms).fadeIn().slideY(begin: 0.06),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openTaskDetail(BuildContext context, TaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskDetailSheet(task: task, isViewer: false),
    );
  }
}

class _PulseAsyncBlock extends StatelessWidget {
  final bool isAr;
  final AsyncValue<List<TaskModel>> tasks;
  final AsyncValue<List<TechnicianModel>> technicians;
  final AsyncValue<List<AdminDeviceModel>> devices;
  final ValueChanged<TaskModel> onTaskTap;

  const _PulseAsyncBlock({
    required this.isAr,
    required this.tasks,
    required this.technicians,
    required this.devices,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    return tasks.when(
      loading: () => const AdminShimmerList(count: 3),
      error: (e, _) => _ErrorCard(message: e.toString()),
      data: (taskList) => technicians.when(
        loading: () => const AdminShimmerList(count: 3),
        error: (e, _) => _ErrorCard(message: e.toString()),
        data: (techList) => devices.when(
          loading: () => const AdminShimmerList(count: 3),
          error: (e, _) => _ErrorCard(message: e.toString()),
          data: (deviceList) => _OperationsPulseSection(
            isAr: isAr,
            tasks: taskList,
            technicians: techList,
            devices: deviceList,
            onTaskTap: onTaskTap,
          ),
        ),
      ),
    );
  }
}

class _OperationsPulseSection extends StatelessWidget {
  final bool isAr;
  final List<TaskModel> tasks;
  final List<TechnicianModel> technicians;
  final List<AdminDeviceModel> devices;
  final ValueChanged<TaskModel> onTaskTap;

  const _OperationsPulseSection({
    required this.isAr,
    required this.tasks,
    required this.technicians,
    required this.devices,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final sortedTasks = [...tasks]
      ..sort((a, b) => _taskMoment(b).compareTo(_taskMoment(a)));
    final latestTask = sortedTasks.isEmpty ? null : sortedTasks.first;

    final sortedTechs = technicians
        .where((t) => t.lastActivity != null)
        .toList()
      ..sort((a, b) => b.lastActivity!.compareTo(a.lastActivity!));
    final latestTech = sortedTechs.isEmpty ? null : sortedTechs.first;

    final sortedDevices = devices
        .where((d) => d.lastInspectionAt != null)
        .toList()
      ..sort((a, b) => b.lastInspectionAt!.compareTo(a.lastInspectionAt!));
    final latestDevice = sortedDevices.isEmpty ? null : sortedDevices.first;

    final activeTasks = tasks
        .where((t) => t.status == 'PENDING' || t.status == 'IN_PROGRESS')
        .length;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0C2149), Color(0xFF173B78), Color(0xFF1E5AA7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'آخر حركة على النظام' : 'Latest movement across the system',
                style: AppText.bodyMed.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                latestTask == null
                    ? (isAr ? 'لا توجد أنشطة حديثة بعد' : 'No recent activity yet')
                    : _taskHeadline(latestTask, isAr),
                style: AppText.h3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                latestTask == null
                    ? (isAr
                        ? 'ابدئي من شاشة المهام أو التفتيش لإظهار النبض التشغيلي هنا.'
                        : 'Start from tasks or inspections to surface live activity here.')
                    : _taskSubhead(latestTask, isAr),
                style: AppText.caption.copyWith(color: Colors.white70, height: 1.45),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 640;
                  final cards = [
                    _PulseMiniCard(
                      icon: Icons.playlist_play_rounded,
                      title: isAr ? 'المهام النشطة' : 'Active Tasks',
                      value: '$activeTasks',
                      subtitle: isAr ? 'قيد المتابعة الآن' : 'being followed now',
                      color: const Color(0xFF9AD1FF),
                    ),
                    _PulseMiniCard(
                      icon: Icons.person_pin_circle_rounded,
                      title: isAr ? 'آخر فني نشط' : 'Latest Technician',
                      value: latestTech?.fullName ?? (isAr ? 'لا يوجد' : 'No one yet'),
                      subtitle: latestTech?.lastActivity == null
                          ? (isAr ? 'لا يوجد نشاط' : 'No activity')
                          : _timeAgo(latestTech!.lastActivity!, isAr),
                      color: const Color(0xFF8FF0D2),
                    ),
                    _PulseMiniCard(
                      icon: Icons.devices_fold_rounded,
                      title: isAr ? 'آخر جهاز تم لمسه' : 'Latest Device',
                      value: latestDevice?.name ?? (isAr ? 'لا يوجد' : 'None'),
                      subtitle: latestDevice?.lastInspectionAt == null
                          ? (isAr ? 'بدون فحص' : 'No inspection yet')
                          : _timeAgo(latestDevice!.lastInspectionAt!, isAr),
                      color: const Color(0xFFFFD28F),
                    ),
                  ];

                  if (compact) {
                    return Column(
                      children: [
                        for (var i = 0; i < cards.length; i++) ...[
                          cards[i],
                          if (i != cards.length - 1) const SizedBox(height: 10),
                        ],
                      ],
                    );
                  }

                  return Row(
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        Expanded(child: cards[i]),
                        if (i != cards.length - 1) const SizedBox(width: 10),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (sortedTasks.isEmpty)
          _EmptyCard(
            label: isAr ? 'لا توجد مهام لعرض آخر النشاط' : 'No tasks to build activity from',
          )
        else
          Column(
            children: sortedTasks.take(3).map((task) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RecentActivityTile(
                  task: task,
                  isAr: isAr,
                  onTap: () => onTaskTap(task),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  static DateTime _taskMoment(TaskModel task) => task.completedAt ?? task.createdAt;

  static String _taskHeadline(TaskModel task, bool isAr) {
    final action = switch (task.status) {
      'COMPLETED' => isAr ? 'اكتملت المهمة الأخيرة' : 'Latest completion recorded',
      'IN_PROGRESS' => isAr ? 'هناك متابعة جارية الآن' : 'There is an active follow-up now',
      _ => isAr ? 'تم إنشاء متابعة جديدة' : 'A new follow-up was created',
    };
    return '$action${task.deviceName != null ? isAr ? ' على ${task.deviceName}' : ' on ${task.deviceName}' : ''}';
  }

  static String _taskSubhead(TaskModel task, bool isAr) {
    final tech = task.assignedToName ?? (isAr ? 'فني غير محدد' : 'Unassigned technician');
    final place = task.locationName ?? task.deviceCode ?? '';
    if (place.isEmpty) {
      return isAr ? 'مسندة إلى $tech' : 'Assigned to $tech';
    }
    return isAr ? 'مسندة إلى $tech في $place' : 'Assigned to $tech at $place';
  }
}

class _RecentActivityTile extends StatelessWidget {
  final TaskModel task;
  final bool isAr;
  final VoidCallback onTap;

  const _RecentActivityTile({
    required this.task,
    required this.isAr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (task.status) {
      'COMPLETED' => AppColors.success,
      'IN_PROGRESS' => AppColors.info,
      'OVERDUE' => AppColors.error,
      _ => AppColors.warning,
    };

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.14)),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.bolt_rounded, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyMed.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.deviceName != null
                          ? (isAr
                              ? 'آخر متابعة تمت على ${task.deviceName}'
                              : 'Latest update happened on ${task.deviceName}')
                          : (isAr ? 'آخر متابعة بدون جهاز محدد' : 'Latest update without linked device'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniTag(
                          text: task.assignedToName ?? (isAr ? 'بدون فني' : 'No technician'),
                          color: AppColors.primary,
                        ),
                        _MiniTag(
                          text: isAr ? task.statusAr : task.statusEn,
                          color: color,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _timeAgo(task.completedAt ?? task.createdAt, isAr),
                style: AppText.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseMiniCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _PulseMiniCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppText.caption.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.bodyMed.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniTag({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppText.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EfficiencyHeroCard extends StatelessWidget {
  final AdminStats stats;

  const _EfficiencyHeroCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final totalDevices = stats.totalDevices == 0 ? 1 : stats.totalDevices;
    final healthyRate = ((stats.okDevices / totalDevices) * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).isAr ? 'جاهزية الأجهزة' : 'Device Readiness',
            style: AppText.bodyMed.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$healthyRate',
                style: AppText.h1.copyWith(color: Colors.white, fontSize: 48),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '%',
                  style: AppText.h3.copyWith(color: AppColors.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniTag(
                text: '${stats.okDevices} ${AppLocalizations.of(context).isAr ? 'سليم' : 'Healthy'}',
                color: AppColors.success,
              ),
              _MiniTag(
                text: '${stats.maintenanceDevices} ${AppLocalizations.of(context).isAr ? 'صيانة' : 'Maintenance'}',
                color: AppColors.warning,
              ),
              _MiniTag(
                text: '${stats.outOfServiceDevices} ${AppLocalizations.of(context).isAr ? 'خارج الخدمة' : 'Out of service'}',
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();

  @override
  Widget build(BuildContext context) => const AdminShimmerList(count: 2);
}

class _AnalyticsLoading extends StatelessWidget {
  const _AnalyticsLoading();

  @override
  Widget build(BuildContext context) => const AdminShimmerList(count: 4);
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorCard({
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: AppText.bodyMed.copyWith(color: AppColors.error)),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context).isAr ? 'إعادة المحاولة' : 'Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String label;

  const _EmptyCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: AppText.bodyMed.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

String _timeAgo(DateTime dt, bool isAr) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) {
    return isAr ? 'منذ ${diff.inMinutes} دقيقة' : '${diff.inMinutes} min ago';
  }
  if (diff.inHours < 24) {
    return isAr ? 'منذ ${diff.inHours} ساعة' : '${diff.inHours}h ago';
  }
  return isAr ? 'منذ ${diff.inDays} يوم' : '${diff.inDays}d ago';
}
