import 'dart:math' as math;

import 'package:access_track/admin/admin_analytics_screen.dart';
import 'package:access_track/admin/admin_inspections_screen.dart';
import 'package:access_track/admin/admin_models.dart';
import 'package:access_track/admin/admin_providers.dart';
import 'package:access_track/admin/admin_tasks_screen.dart';
import 'package:access_track/admin/admin_technicians_screen.dart';
import 'package:access_track/admin/admin_widgets.dart';
import 'package:access_track/app_localizations.dart';
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
    final isAr = AppLocalizations.of(context).isAr;

    final statsAsync = ref.watch(adminStatsProvider);
    final tasksAsync = ref.watch(allTasksProvider);
    final activeTechsAsync = ref.watch(activeTechniciansProvider);
    final devicesAsync = ref.watch(adminDevicesProvider(null));
    final inspectionsAsync = ref.watch(monthlyInspectionsProvider);
    final analyticsAsync = ref.watch(adminAnalyticsProvider);

    void refreshAll() {
      ref.invalidate(adminStatsProvider);
      ref.invalidate(adminAnalyticsProvider);
      ref.invalidate(allTasksProvider);
      ref.invalidate(activeTechniciansProvider);
      ref.invalidate(techniciansProvider);
      ref.invalidate(adminDevicesProvider(null));
      ref.invalidate(monthlyInspectionsProvider);
      ref.invalidate(locationsProvider);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: RefreshIndicator(
        onRefresh: () async => refreshAll(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 192,
              pinned: true,
              elevation: 0,
              backgroundColor: const Color(0xFF0F172A),
              leading: IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: onLogout,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: refreshAll,
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _HeroHeader(adminName: adminName, isAr: isAr),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AsyncDashboardSummary(
                      isAr: isAr,
                      statsAsync: statsAsync,
                      tasksAsync: tasksAsync,
                      activeTechsAsync: activeTechsAsync,
                      inspectionsAsync: inspectionsAsync,
                      onRetry: refreshAll,
                    ),
                    const SizedBox(height: 16),
                    _ReadinessCard(
                      isAr: isAr,
                      tasksAsync: tasksAsync,
                      devicesAsync: devicesAsync,
                      onRetry: refreshAll,
                    ),
                    const SizedBox(height: 22),
                    _SectionHeader(
                      title: isAr ? 'نبض التشغيل الحقيقي' : 'Real Operations Pulse',
                      icon: Icons.radar_rounded,
                      action: isAr ? 'كل المهام' : 'All tasks',
                      onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminTasksScreen(initialFilter: 'ALL'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _LivePulse(
                      isAr: isAr,
                      tasksAsync: tasksAsync,
                      activeTechsAsync: activeTechsAsync,
                      devicesAsync: devicesAsync,
                      inspectionsAsync: inspectionsAsync,
                      onRetry: refreshAll,
                    ),
                    const SizedBox(height: 22),
                    _SectionHeader(
                      title: isAr ? 'إجراءات سريعة' : 'Quick Actions',
                      icon: Icons.bolt_rounded,
                    ),
                    const SizedBox(height: 10),
                    _QuickActions(isAr: isAr),
                    const SizedBox(height: 22),
                    _SectionHeader(
                      title: isAr ? 'ملخص التحليلات' : 'Analytics Preview',
                      icon: Icons.analytics_rounded,
                      action: isAr ? 'فتح التحليلات' : 'Open analytics',
                      onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen()),
                      ),
                    ),
                    const SizedBox(height: 10),
                    analyticsAsync.when(
                      loading: () => const _LoadingBlock(height: 160),
                      error: (e, _) => _ErrorPanel(message: e.toString(), onRetry: refreshAll),
                      data: (analytics) => _AnalyticsPreview(analytics: analytics, isAr: isAr),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String adminName;
  final bool isAr;

  const _HeroHeader({required this.adminName, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(right: -60, top: -50, child: _Glow(size: 220, color: Colors.white.withOpacity(0.10))),
          Positioned(left: -70, bottom: -80, child: _Glow(size: 190, color: const Color(0xFF67E8F9).withOpacity(0.14))),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.16)),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? 'أهلاً يا' : 'Welcome back,',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.72),
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          adminName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            fontSize: 25,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isAr ? 'أرقام محسوبة من الداتا نفسها وليس من كروت ثابتة' : 'Numbers calculated from real loaded data',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontFamily: 'Cairo',
                            fontSize: 12,
                          ),
                        ),
                      ],
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
}

class _AsyncDashboardSummary extends StatelessWidget {
  final bool isAr;
  final AsyncValue<AdminStats> statsAsync;
  final AsyncValue<List<TaskModel>> tasksAsync;
  final AsyncValue<List<TechnicianModel>> activeTechsAsync;
  final AsyncValue<List<InspectionDetail>> inspectionsAsync;
  final VoidCallback onRetry;

  const _AsyncDashboardSummary({
    required this.isAr,
    required this.statsAsync,
    required this.tasksAsync,
    required this.activeTechsAsync,
    required this.inspectionsAsync,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (tasksAsync.isLoading || activeTechsAsync.isLoading || inspectionsAsync.isLoading) {
      return const _LoadingBlock(height: 128);
    }

    if (tasksAsync.hasError) return _ErrorPanel(message: tasksAsync.error.toString(), onRetry: onRetry);

    final tasks = tasksAsync.valueOrNull ?? const <TaskModel>[];
    final activeTechs = activeTechsAsync.valueOrNull ?? const <TechnicianModel>[];
    final inspections = inspectionsAsync.valueOrNull ?? const <InspectionDetail>[];
    final stats = statsAsync.valueOrNull;

    final totalTasks = tasks.isNotEmpty ? tasks.length : (stats?.totalTasks ?? 0);
    final completedTasks = tasks.where((t) => t.status.toUpperCase() == 'COMPLETED').length;
    final pendingTasks = tasks.where((t) => t.status.toUpperCase() == 'PENDING').length;
    final inProgressTasks = tasks.where((t) => t.status.toUpperCase() == 'IN_PROGRESS').length;
    final urgentTasks = tasks.where((t) => t.isUrgent || t.isEmergency || t.priority.toUpperCase() == 'URGENT').length;
    final inspectionCount = inspections.isNotEmpty ? inspections.length : (stats?.totalInspectionsMonth ?? 0);

    final cards = [
      _StatData(
        title: isAr ? 'كل المهام' : 'All tasks',
        value: totalTasks,
        subtitle: '${isAr ? 'معلقة' : 'Pending'} $pendingTasks • ${isAr ? 'جارية' : 'Running'} $inProgressTasks',
        icon: Icons.assignment_rounded,
        color: const Color(0xFF1A237E),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTasksScreen(initialFilter: 'ALL'))),
      ),
      _StatData(
        title: isAr ? 'مهام مكتملة' : 'Completed',
        value: completedTasks,
        subtitle: isAr ? 'محسوبة من كل المهام المحملة' : 'Calculated from loaded tasks',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF16A34A),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTasksScreen(initialFilter: 'COMPLETED'))),
      ),
      _StatData(
        title: isAr ? 'الفنيين النشطين' : 'Active techs',
        value: activeTechs.length,
        subtitle: isAr ? 'يظهر الفنيين فقط' : 'Technicians only',
        icon: Icons.engineering_rounded,
        color: const Color(0xFF0F766E),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTechniciansScreen())),
      ),
      _StatData(
        title: isAr ? 'تفتيشات الشهر' : 'Month checks',
        value: inspectionCount,
        subtitle: '${isAr ? 'طارئة' : 'Urgent'} $urgentTasks',
        icon: Icons.fact_check_rounded,
        color: const Color(0xFF7C3AED),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminInspectionsScreen())),
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final two = c.maxWidth < 680;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: cards.map((card) {
            return SizedBox(
              width: two ? (c.maxWidth - 10) / 2 : (c.maxWidth - 30) / 4,
              child: _StatCard(data: card),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  final bool isAr;
  final AsyncValue<List<TaskModel>> tasksAsync;
  final AsyncValue<List<AdminDeviceModel>> devicesAsync;
  final VoidCallback onRetry;

  const _ReadinessCard({
    required this.isAr,
    required this.tasksAsync,
    required this.devicesAsync,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (tasksAsync.isLoading || devicesAsync.isLoading) return const _LoadingBlock(height: 142);
    if (tasksAsync.hasError) return _ErrorPanel(message: tasksAsync.error.toString(), onRetry: onRetry);

    final tasks = tasksAsync.valueOrNull ?? const <TaskModel>[];
    final devices = devicesAsync.valueOrNull ?? const <AdminDeviceModel>[];

    final completed = tasks.where((t) => t.status.toUpperCase() == 'COMPLETED').length;
    final okDevices = devices.where((d) => d.currentStatus.toUpperCase() == 'OK').length;
    final faults = devices.where((d) {
      final s = d.currentStatus.toUpperCase();
      return s == 'OUT_OF_SERVICE' || s == 'NOT_OK' || s == 'NOT_REACHABLE';
    }).length;
    final overdue = tasks.where((t) => t.status.toUpperCase() == 'OVERDUE').length;

    final taskScore = tasks.isEmpty ? 0.0 : completed / tasks.length;
    final deviceScore = devices.isEmpty ? 0.0 : okDevices / devices.length;
    double score = tasks.isEmpty && devices.isEmpty ? 0.0 : (taskScore * 0.52) + (deviceScore * 0.48);
    if (overdue > 0) score -= 0.08;
    if (faults > 0) score -= 0.06;
    score = score.clamp(0.0, 1.0);

    final percent = (score * 100).round();
    final color = percent >= 80
        ? const Color(0xFF16A34A)
        : percent >= 55
            ? const Color(0xFFF59E0B)
            : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.16)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 18, offset: const Offset(0, 7))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            height: 104,
            child: CustomPaint(
              painter: _RingPainter(value: score, color: color),
              child: Center(
                child: Text(
                  '$percent%',
                  style: TextStyle(color: color, fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 22),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'جاهزية النظام' : 'System readiness',
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 5),
                Text(
                  isAr ? 'محسوبة من المهام المكتملة وحالة الأجهزة الحقيقية.' : 'Calculated from completed tasks and real device health.',
                  style: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF64748B), fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Pill(text: '$completed ${isAr ? 'مهمة مكتملة' : 'completed'}', color: const Color(0xFF16A34A)),
                    _Pill(text: '$overdue ${isAr ? 'متأخرة' : 'overdue'}', color: const Color(0xFFF59E0B)),
                    _Pill(text: '$faults ${isAr ? 'أعطال' : 'faults'}', color: const Color(0xFFDC2626)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePulse extends StatelessWidget {
  final bool isAr;
  final AsyncValue<List<TaskModel>> tasksAsync;
  final AsyncValue<List<TechnicianModel>> activeTechsAsync;
  final AsyncValue<List<AdminDeviceModel>> devicesAsync;
  final AsyncValue<List<InspectionDetail>> inspectionsAsync;
  final VoidCallback onRetry;

  const _LivePulse({
    required this.isAr,
    required this.tasksAsync,
    required this.activeTechsAsync,
    required this.devicesAsync,
    required this.inspectionsAsync,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (tasksAsync.isLoading || activeTechsAsync.isLoading || devicesAsync.isLoading || inspectionsAsync.isLoading) {
      return const _LoadingBlock(height: 270);
    }
    if (tasksAsync.hasError) return _ErrorPanel(message: tasksAsync.error.toString(), onRetry: onRetry);

    final tasks = tasksAsync.valueOrNull ?? const <TaskModel>[];
    final techs = activeTechsAsync.valueOrNull ?? const <TechnicianModel>[];
    final devices = devicesAsync.valueOrNull ?? const <AdminDeviceModel>[];
    final inspections = inspectionsAsync.valueOrNull ?? const <InspectionDetail>[];

    final sortedTasks = [...tasks]..sort((a, b) => _taskDate(b).compareTo(_taskDate(a)));
    final latestTask = sortedTasks.isEmpty ? null : sortedTasks.first;
    final activeTasks = tasks.where((t) {
      final s = t.status.toUpperCase();
      return s == 'PENDING' || s == 'IN_PROGRESS' || s == 'OVERDUE';
    }).length;
    final latestInspection = ([...inspections]..sort((a, b) => b.inspectedAt.compareTo(a.inspectedAt))).firstOrNull;
    final latestDevice = ([...devices.where((d) => d.lastInspectionAt != null)]..sort((a, b) => b.lastInspectionAt!.compareTo(a.lastInspectionAt!))).firstOrNull;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)]),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'آخر نشاط' : 'Latest activity',
                style: TextStyle(color: Colors.white.withOpacity(.65), fontFamily: 'Cairo', fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 7),
              Text(
                latestTask?.title ?? (isAr ? 'لا توجد مهام بعد' : 'No tasks yet'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 19),
              ),
              const SizedBox(height: 8),
              Text(
                latestTask == null
                    ? (isAr ? 'أي مهمة أو تفتيش سيظهر هنا مباشرة.' : 'Any task or inspection appears here directly.')
                    : '${latestTask.assignedToName ?? '-'} • ${latestTask.deviceName ?? '-'}',
                style: TextStyle(color: Colors.white.withOpacity(.64), fontFamily: 'Cairo', fontSize: 12),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (_, c) {
                  final compact = c.maxWidth < 680;
                  final cards = [
                    _DarkPulse(icon: Icons.playlist_play_rounded, title: isAr ? 'مهام نشطة' : 'Active tasks', value: '$activeTasks', color: const Color(0xFF93C5FD)),
                    _DarkPulse(icon: Icons.engineering_rounded, title: isAr ? 'فنيين نشطين' : 'Active techs', value: '${techs.length}', color: const Color(0xFF86EFAC)),
                    _DarkPulse(icon: Icons.devices_rounded, title: isAr ? 'آخر جهاز' : 'Latest device', value: latestDevice?.name ?? '-', color: const Color(0xFFFDE68A)),
                    _DarkPulse(icon: Icons.fact_check_rounded, title: isAr ? 'آخر فحص' : 'Latest check', value: latestInspection?.deviceName ?? '-', color: const Color(0xFFFCA5A5)),
                  ];
                  if (compact) {
                    return Column(
                      children: cards.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: e)).toList(),
                    );
                  }
                  return Row(
                    children: cards.map((e) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: e))).toList(),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...sortedTasks.take(4).map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MiniTaskTile(task: t, isAr: isAr),
            )),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final bool isAr;
  const _QuickActions({required this.isAr});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionData(isAr ? 'كل المهام' : 'All tasks', Icons.task_alt_rounded, const Color(0xFF1A237E), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTasksScreen(initialFilter: 'ALL')))),
      _ActionData(isAr ? 'الفنيين' : 'Technicians', Icons.engineering_rounded, const Color(0xFF0F766E), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTechniciansScreen()))),
      _ActionData(isAr ? 'التفتيشات' : 'Inspections', Icons.fact_check_rounded, const Color(0xFF7C3AED), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminInspectionsScreen()))),
      _ActionData(isAr ? 'التحليلات' : 'Analytics', Icons.analytics_rounded, const Color(0xFFF59E0B), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen()))),
    ];

    return LayoutBuilder(
      builder: (_, c) {
        final two = c.maxWidth < 680;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: actions.map((a) => SizedBox(
                width: two ? (c.maxWidth - 10) / 2 : (c.maxWidth - 30) / 4,
                child: _ActionCard(data: a),
              )).toList(),
        );
      },
    );
  }
}

class _AnalyticsPreview extends StatelessWidget {
  final AdminAnalyticsData analytics;
  final bool isAr;

  const _AnalyticsPreview({required this.analytics, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SimpleBar(label: isAr ? 'المهام المكتملة' : 'Completed tasks', value: analytics.stats.completedTasks, total: math.max(analytics.stats.totalTasks, 1), color: const Color(0xFF16A34A)),
        const SizedBox(height: 8),
        _SimpleBar(label: isAr ? 'الأجهزة السليمة' : 'Healthy devices', value: analytics.stats.okDevices, total: math.max(analytics.stats.totalDevices, 1), color: const Color(0xFF1A237E)),
        const SizedBox(height: 8),
        _SimpleBar(label: isAr ? 'فحوصات الشهر' : 'Month inspections', value: analytics.stats.totalInspectionsMonth, total: math.max(analytics.stats.totalInspectionsMonth + analytics.stats.openReports, 1), color: const Color(0xFF7C3AED)),
      ],
    );
  }
}

class _StatData {
  final String title;
  final int value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: data.onTap,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: data.color.withOpacity(0.12)),
              boxShadow: [BoxShadow(color: data.color.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(data.icon, color: data.color, size: 25),
                const SizedBox(height: 11),
                Text('${data.value}', style: TextStyle(color: data.color, fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 25)),
                Text(data.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, color: Color(0xFF475569), fontSize: 12)),
                const SizedBox(height: 2),
                Text(data.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF94A3B8), fontSize: 10.5)),
              ],
            ),
          ),
        ),
      );
}

class _MiniTaskTile extends StatelessWidget {
  final TaskModel task;
  final bool isAr;

  const _MiniTaskTile({required this.task, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final color = _taskColor(task);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => TaskDetailSheet(task: task, isViewer: false),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(.12)),
          ),
          child: Row(
            children: [
              Icon(Icons.bolt_rounded, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900)),
                    Text('${task.assignedToName ?? '-'} • ${task.deviceName ?? '-'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              _Pill(text: isAr ? task.statusAr : task.statusEn, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _DarkPulse extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _DarkPulse({required this.icon, required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: Colors.white.withOpacity(.62), fontFamily: 'Cairo', fontSize: 10)),
            const SizedBox(height: 3),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 14)),
          ],
        ),
      );
}

class _ActionData {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionData(this.title, this.icon, this.color, this.onTap);
}

class _ActionCard extends StatelessWidget {
  final _ActionData data;
  const _ActionCard({required this.data});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: data.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: data.color.withOpacity(.14)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(data.icon, color: data.color),
                const SizedBox(height: 10),
                Text(data.title, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, required this.icon, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: const Color(0xFF1A237E)),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)))),
          if (action != null && onAction != null) TextButton(onPressed: onAction, child: Text(action!)),
        ],
      );
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: TextStyle(color: color, fontFamily: 'Cairo', fontSize: 10.5, fontWeight: FontWeight.w900)),
      );
}

class _SimpleBar extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _SimpleBar({required this.label, required this.value, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final p = total == 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(.12))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900))),
              Text('$value', style: TextStyle(color: color, fontFamily: 'Cairo', fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: p, minHeight: 8, backgroundColor: const Color(0xFFE2E8F0), valueColor: AlwaysStoppedAnimation(color)),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;

  const _RingPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 8;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      value * 2 * math.pi,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.value != value || old.color != color;
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;
  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

class _LoadingBlock extends StatelessWidget {
  final double height;
  const _LoadingBlock({this.height = 110});

  @override
  Widget build(BuildContext context) => Container(height: height, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 900.ms);
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorPanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(color: Color(0xFFDC2626))),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}

DateTime _taskDate(TaskModel task) => task.completedAt ?? task.dueDate ?? task.createdAt;

Color _taskColor(TaskModel task) {
  final s = task.status.toUpperCase();
  if (task.isUrgent || task.isEmergency || task.priority.toUpperCase() == 'URGENT') return const Color(0xFFDC2626);
  if (s == 'COMPLETED') return const Color(0xFF16A34A);
  if (s == 'IN_PROGRESS') return const Color(0xFF0284C7);
  if (s == 'OVERDUE') return const Color(0xFFEA580C);
  return const Color(0xFF1A237E);
}

extension _FirstOrNullX<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) {
      return item;
    }
    return null;
  }
}
