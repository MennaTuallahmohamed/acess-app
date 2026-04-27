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

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────

class _DT {
  static const r6 = Radius.circular(6);
  static const r12 = Radius.circular(12);
  static const r16 = Radius.circular(16);
  static const r20 = Radius.circular(20);
  static const r24 = Radius.circular(24);
  static const r32 = Radius.circular(32);
  static const r999 = Radius.circular(999);

  static const gradientHero = LinearGradient(
    colors: [Color(0xFF0B1D3A), Color(0xFF0F3460), Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientPulse = LinearGradient(
    colors: [Color(0xFF0C2149), Color(0xFF183A7A), Color(0xFF1E5AA7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientSuccess = LinearGradient(
    colors: [Color(0xFF064E3B), Color(0xFF065F46)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const shadowSoft = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 20,
      offset: Offset(0, 8),
      spreadRadius: -2,
    ),
  ];

  static const shadowCard = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const c50 = Color(0xFFF8FAFC);
  static const c100 = Color(0xFFF1F5F9);
  static const c200 = Color(0xFFE2E8F0);
  static const c400 = Color(0xFF94A3B8);
  static const c600 = Color(0xFF475569);
  static const c900 = Color(0xFF0F172A);

  static const blue = Color(0xFF1565C0);
  static const blueLight = Color(0xFFE3F2FD);
  static const green = Color(0xFF059669);
  static const greenLight = Color(0xFFD1FAE5);
  static const amber = Color(0xFFD97706);
  static const amberLight = Color(0xFFFEF3C7);
  static const red = Color(0xFFDC2626);
  static const redLight = Color(0xFFFEE2E2);
  static const cyan = Color(0xFF0284C7);

  // Text styles
  static const _base = TextStyle(fontFamily: 'Cairo');
  static final h1 = _base.copyWith(
      fontSize: 32, fontWeight: FontWeight.w900, color: c900, height: 1.1);
  static final h2 = _base.copyWith(
      fontSize: 22, fontWeight: FontWeight.w900, color: c900, height: 1.2);
  static final h3 = _base.copyWith(
      fontSize: 17, fontWeight: FontWeight.w800, color: c900, height: 1.3);
  static final body = _base.copyWith(
      fontSize: 13.5, fontWeight: FontWeight.w600, color: c600, height: 1.5);
  static final bodyBold = _base.copyWith(
      fontSize: 13.5, fontWeight: FontWeight.w800, color: c900, height: 1.5);
  static final caption = _base.copyWith(
      fontSize: 11, fontWeight: FontWeight.w600, color: c400, height: 1.4);
  static final captionBold = _base.copyWith(
      fontSize: 11, fontWeight: FontWeight.w800, color: c400, height: 1.4);
  static final micro = _base.copyWith(
      fontSize: 9.5, fontWeight: FontWeight.w700, color: c400, height: 1.3);
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

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

    void refreshAll() {
      ref.invalidate(adminStatsProvider);
      ref.invalidate(allTasksProvider);
      ref.invalidate(techniciansProvider);
      ref.invalidate(adminDevicesProvider(null));
      ref.invalidate(adminAnalyticsProvider);
    }

    return Scaffold(
      backgroundColor: _DT.c50,
      body: CustomScrollView(
        slivers: [
          _DashboardAppBar(
            adminName: adminName,
            onLogout: onLogout,
            onRefresh: refreshAll,
            isAr: l.isAr,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 24),
                _SectionLabel(
                  title: l.isAr ? 'الملخص العام' : 'General Summary',
                  icon: Icons.insights_rounded,
                ).animate().fadeIn().slideY(begin: 0.08),
                const SizedBox(height: 14),
                stats.when(
                  loading: () => const _StatsShimmer(),
                  error: (e, _) => _ErrorCard(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(adminStatsProvider),
                  ),
                  data: (s) => _StatsGrid(stats: s, isAr: l.isAr),
                ).animate(delay: 80.ms).fadeIn(),
                const SizedBox(height: 28),
                _SectionLabel(
                  title: l.isAr ? 'نبض التشغيل' : 'Operations Pulse',
                  icon: Icons.motion_photos_on_rounded,
                  actionLabel: l.isAr ? 'كل المهام' : 'All Tasks',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminTasksScreen()),
                  ),
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
                _SectionLabel(
                  title: l.isAr ? 'التحليلات المتقدمة' : 'Advanced Analytics',
                  icon: Icons.auto_graph_rounded,
                  actionLabel: l.isAr ? 'المزيد' : 'More',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminAnalyticsScreen()),
                  ),
                ).animate(delay: 220.ms).fadeIn(),
                const SizedBox(height: 16),
                analytics.when(
                  loading: () => const _AnalyticsLoading(),
                  error: (e, _) => _ErrorCard(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(adminAnalyticsProvider),
                  ),
                  data: (a) => _AnalyticsSection(analytics: a, isAr: l.isAr),
                ),
              ]),
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

// ─────────────────────────────────────────────────────────────────────────────
// APP BAR
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardAppBar extends StatelessWidget {
  final String adminName;
  final bool isAr;
  final VoidCallback onLogout;
  final VoidCallback onRefresh;

  const _DashboardAppBar({
    required this.adminName,
    required this.isAr,
    required this.onLogout,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      elevation: 0,
      backgroundColor: _DT.blue,
      leading: _AppBarBtn(icon: Icons.logout_rounded, onTap: onLogout),
      actions: [
        _AppBarBtn(icon: Icons.refresh_rounded, onTap: onRefresh),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        centerTitle: false,
        title: _AppBarTitle(adminName: adminName, isAr: isAr),
        background: _AppBarBackground(),
      ),
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  final String adminName;
  final bool isAr;

  const _AppBarTitle({required this.adminName, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'لوحة المتابعة' : 'Operations Home',
          style: _DT.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          adminName,
          style: _DT.caption.copyWith(color: Colors.white70, fontSize: 10.5),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _AppBarBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: _DT.gradientHero),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -30,
            top: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            right: 40,
            top: 20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // Grid pattern overlay
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AppBarBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AppBarBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 22),
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionLabel({
    required this.title,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: _DT.gradientHero,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: _DT.h3,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _DT.blueLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style:
                        _DT.captionBold.copyWith(color: _DT.blue, fontSize: 11),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 10, color: _DT.blue),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS GRID
// ─────────────────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final AdminStats stats;
  final bool isAr;

  const _StatsGrid({required this.stats, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(
        icon: Icons.people_rounded,
        value: stats.totalTechnicians.toString(),
        label: isAr ? 'الفنيون' : 'Technicians',
        color: _DT.blue,
        bg: _DT.blueLight,
      ),
      _StatItem(
        icon: Icons.devices_rounded,
        value: stats.totalDevices.toString(),
        label: isAr ? 'الأجهزة' : 'Devices',
        color: _DT.cyan,
        bg: const Color(0xFFE0F2FE),
      ),
      _StatItem(
        icon: Icons.task_alt_rounded,
        value: stats.completedTasks.toString(),
        label: isAr ? 'مكتملة' : 'Completed',
        color: _DT.green,
        bg: _DT.greenLight,
      ),
      _StatItem(
        icon: Icons.assignment_late_rounded,
        value: stats.openReports.toString(),
        label: isAr ? 'تقارير مفتوحة' : 'Open Reports',
        color: _DT.amber,
        bg: _DT.amberLight,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.75,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: items
              .asMap()
              .entries
              .map(
                (e) => _StatCard(item: e.value)
                    .animate(delay: (e.key * 50).ms)
                    .fadeIn()
                    .slideY(begin: 0.06),
              )
              .toList(),
        );
      },
    );
  }
}

class _StatItem {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color bg;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem item;

  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _DT.shadowCard,
        border: Border.all(color: item.color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.value,
                  style: _DT.h2.copyWith(color: item.color, fontSize: 24),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.label,
                  style: _DT.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PULSE SECTION
// ─────────────────────────────────────────────────────────────────────────────

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
        // Hero pulse card
        _PulseHeroCard(
          isAr: isAr,
          latestTask: latestTask,
          latestTech: latestTech,
          latestDevice: latestDevice,
          activeTasks: activeTasks,
        ),
        const SizedBox(height: 14),
        // Recent tasks
        if (sortedTasks.isEmpty)
          _EmptyCard(
            label: isAr
                ? 'لا توجد مهام لعرض آخر النشاط'
                : 'No tasks to show activity from',
          )
        else
          ...sortedTasks.take(3).map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RecentActivityTile(
                  task: task,
                  isAr: isAr,
                  onTap: () => onTaskTap(task),
                ),
              )),
      ],
    );
  }

  static DateTime _taskMoment(TaskModel task) => task.completedAt ?? task.createdAt;
}

class _PulseHeroCard extends StatelessWidget {
  final bool isAr;
  final TaskModel? latestTask;
  final TechnicianModel? latestTech;
  final AdminDeviceModel? latestDevice;
  final int activeTasks;

  const _PulseHeroCard({
    required this.isAr,
    required this.latestTask,
    required this.latestTech,
    required this.latestDevice,
    required this.activeTasks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _DT.gradientPulse,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _DT.shadowSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4ADE80),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isAr ? 'نشط الآن' : 'Live',
                  style: _DT.micro.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Headline
          Text(
            isAr ? 'آخر حركة على النظام' : 'Latest System Activity',
            style: _DT.caption.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: 6),
          Text(
            latestTask == null
                ? (isAr ? 'لا توجد أنشطة حديثة' : 'No recent activity yet')
                : _taskHeadline(latestTask!, isAr),
            style: _DT.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            latestTask == null
                ? (isAr
                    ? 'ابدأ من شاشة المهام لإظهار النبض التشغيلي هنا.'
                    : 'Start from tasks to surface live activity here.')
                : _taskSubhead(latestTask!, isAr),
            style: _DT.caption.copyWith(color: Colors.white60, height: 1.5),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 18),
          // Mini cards row
          LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth < 600;
            final cards = [
              _PulseMiniCard(
                icon: Icons.playlist_play_rounded,
                title: isAr ? 'نشطة' : 'Active',
                value: '$activeTasks',
                subtitle: isAr ? 'مهمة الآن' : 'tasks now',
                color: const Color(0xFF93C5FD),
              ),
              _PulseMiniCard(
                icon: Icons.person_pin_circle_rounded,
                title: isAr ? 'آخر فني' : 'Last Tech',
                value: latestTech?.fullName ?? (isAr ? 'لا يوجد' : 'None'),
                subtitle: latestTech?.lastActivity == null
                    ? (isAr ? 'لا نشاط' : 'No activity')
                    : _timeAgo(latestTech!.lastActivity!, isAr),
                color: const Color(0xFF6EE7B7),
              ),
              _PulseMiniCard(
                icon: Icons.devices_fold_rounded,
                title: isAr ? 'آخر جهاز' : 'Last Device',
                value: latestDevice?.name ?? (isAr ? 'لا يوجد' : 'None'),
                subtitle: latestDevice?.lastInspectionAt == null
                    ? (isAr ? 'بدون فحص' : 'No inspection')
                    : _timeAgo(latestDevice!.lastInspectionAt!, isAr),
                color: const Color(0xFFFCD34D),
              ),
            ];

            if (compact) {
              return Column(
                children: cards
                    .asMap()
                    .entries
                    .map((e) => Padding(
                          padding: EdgeInsets.only(
                              bottom: e.key < cards.length - 1 ? 10 : 0),
                          child: e.value,
                        ))
                    .toList(),
              );
            }

            return Row(
              children: cards
                  .asMap()
                  .entries
                  .map((e) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: e.key < cards.length - 1 ? 10 : 0),
                          child: e.value,
                        ),
                      ))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  static String _taskHeadline(TaskModel task, bool isAr) {
    final action = switch (task.status) {
      'COMPLETED' =>
        isAr ? 'اكتملت المهمة الأخيرة' : 'Latest task completed',
      'IN_PROGRESS' =>
        isAr ? 'متابعة جارية الآن' : 'Active follow-up in progress',
      _ => isAr ? 'تم إنشاء متابعة جديدة' : 'New follow-up created',
    };
    final device = task.deviceName;
    if (device == null) return action;
    return '$action${isAr ? ' على $device' : ' on $device'}';
  }

  static String _taskSubhead(TaskModel task, bool isAr) {
    final tech =
        task.assignedToName ?? (isAr ? 'فني غير محدد' : 'Unassigned');
    final place = task.locationName ?? task.deviceCode ?? '';
    if (place.isEmpty) {
      return isAr ? 'مسندة إلى $tech' : 'Assigned to $tech';
    }
    return isAr ? 'مسندة إلى $tech في $place' : 'Assigned to $tech at $place';
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const Spacer(),
              Container(
                  width: 5,
                  height: 5,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title,
              style: _DT.micro.copyWith(color: Colors.white60),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value,
              style: _DT.bodyBold.copyWith(color: Colors.white, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(subtitle,
              style: _DT.micro.copyWith(color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECENT ACTIVITY TILE
// ─────────────────────────────────────────────────────────────────────────────

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
      'COMPLETED' => _DT.green,
      'IN_PROGRESS' => _DT.cyan,
      'OVERDUE' => _DT.red,
      _ => _DT.amber,
    };

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.15)),
            boxShadow: _DT.shadowCard,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.bolt_rounded, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _DT.bodyBold,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      task.deviceName != null
                          ? (isAr
                              ? 'آخر تحديث على ${task.deviceName}'
                              : 'Updated on ${task.deviceName}')
                          : (isAr
                              ? 'تحديث بدون جهاز محدد'
                              : 'Update without linked device'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _DT.caption,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Tag(
                          text: task.assignedToName ??
                              (isAr ? 'بدون فني' : 'No technician'),
                          color: _DT.blue,
                        ),
                        const SizedBox(width: 6),
                        _Tag(
                          text: isAr ? task.statusAr : task.statusEn,
                          color: color,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Time
              Text(
                _timeAgo(task.completedAt ?? task.createdAt, isAr),
                style: _DT.micro.copyWith(
                    color: _DT.c600, fontWeight: FontWeight.w700),
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;

  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: _DT.micro.copyWith(color: color, fontWeight: FontWeight.w800),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANALYTICS SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _AnalyticsSection extends StatelessWidget {
  final AdminAnalyticsData analytics;
  final bool isAr;

  const _AnalyticsSection({required this.analytics, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final a = analytics;
    return Column(
      children: [
        _EfficiencyHeroCard(stats: a.stats),
        const SizedBox(height: 14),
        _AnalyticsChartWrapper(
          title: isAr ? 'حالة الأجهزة' : 'Device Health Status',
          subtitle: isAr
              ? 'توزيع حالة الأجهزة الحالية'
              : 'Current device status distribution',
          icon: Icons.pie_chart_rounded,
          child: DeviceStatusDonutChart(data: a.deviceStatus),
          delay: 260,
        ),
        const SizedBox(height: 14),
        _AnalyticsChartWrapper(
          title: isAr ? 'حالة المهام' : 'Task Status Distribution',
          subtitle: isAr
              ? 'توزيع المهام حسب الحالة'
              : 'Tasks grouped by current status',
          icon: Icons.donut_large_rounded,
          child: TaskStatusDonutChart(data: a.taskStatus),
          delay: 300,
        ),
        const SizedBox(height: 14),
        _AnalyticsChartWrapper(
          title: isAr ? 'الأجهزة حسب المباني' : 'Devices by Building',
          subtitle: isAr
              ? 'أكثر المباني احتواءً على أجهزة'
              : 'Top buildings by device count',
          icon: Icons.apartment_rounded,
          child: DevicesByBuildingBarChart(data: a.devicesByBuilding),
          delay: 340,
        ),
        const SizedBox(height: 14),
        _AnalyticsChartWrapper(
          title: isAr ? 'الأجهزة حسب النوع' : 'Devices by Type',
          subtitle: isAr
              ? 'توزيع الأجهزة حسب النوع'
              : 'Device type distribution',
          icon: Icons.category_rounded,
          child: DevicesByTypeBarChart(data: a.devicesByType),
          delay: 380,
        ),
        const SizedBox(height: 14),
        _AnalyticsChartWrapper(
          title: isAr ? 'اتجاه إنجاز المهام' : 'Task Completion Trend',
          subtitle: isAr ? 'آخر 7 أيام' : 'Last 7 days',
          icon: Icons.show_chart_rounded,
          child: TaskCompletionTrendChart(data: a.taskCompletionTrend),
          delay: 420,
        ),
        const SizedBox(height: 14),
        _AnalyticsChartWrapper(
          title: isAr ? 'أداء الفنيين' : 'Technician Performance',
          subtitle: isAr
              ? 'أفضل الفنيين حسب النشاط'
              : 'Top technicians by activity',
          icon: Icons.groups_rounded,
          child: TechnicianPerformanceBarChart(data: a.technicianPerformance),
          delay: 460,
        ),
        const SizedBox(height: 14),
        _AnalyticsChartWrapper(
          title: isAr ? 'التفتيشات عبر الزمن' : 'Inspections Over Time',
          subtitle: isAr ? 'آخر 7 أيام' : 'Last 7 days',
          icon: Icons.timeline_rounded,
          child: InspectionsOverTimeChart(data: a.inspectionsOverTime),
          delay: 500,
        ),
        const SizedBox(height: 14),
        _AnalyticsChartWrapper(
          title:
              isAr ? 'تنفيذ المهام لكل فني' : 'Task Execution by Technician',
          subtitle: isAr
              ? 'مكتمل وجارٍ ومعلّق'
              : 'Completed vs in progress vs pending',
          icon: Icons.bar_chart_rounded,
          child: TaskExecutionStackedChart(data: a.taskExecutionByTechnician),
          delay: 540,
        ),
      ],
    );
  }
}

class _AnalyticsChartWrapper extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final int delay;

  const _AnalyticsChartWrapper({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _DT.shadowCard,
        border: Border.all(color: _DT.c200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: _DT.gradientHero,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: _DT.bodyBold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(subtitle,
                          style: _DT.micro,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: child,
          ),
        ],
      ),
    )
        .animate(delay: delay.ms)
        .fadeIn()
        .slideY(begin: 0.06);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EFFICIENCY HERO CARD
// ─────────────────────────────────────────────────────────────────────────────

class _EfficiencyHeroCard extends StatelessWidget {
  final AdminStats stats;

  const _EfficiencyHeroCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isAr = AppLocalizations.of(context).isAr;
    final totalDevices = stats.totalDevices == 0 ? 1 : stats.totalDevices;
    final healthyRate = ((stats.okDevices / totalDevices) * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: _DT.gradientHero,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _DT.shadowSoft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ring
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: healthyRate / 100,
                  strokeWidth: 7,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF4ADE80)),
                  strokeCap: StrokeCap.round,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$healthyRate%',
                      style: _DT.h3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20),
                    ),
                    Text(
                      isAr ? 'جيد' : 'OK',
                      style: _DT.micro.copyWith(color: Colors.white60),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'جاهزية الأجهزة' : 'Device Readiness',
                  style: _DT.caption.copyWith(color: Colors.white60),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  isAr ? 'صحة الأسطول' : 'Fleet Health',
                  style: _DT.h3.copyWith(color: Colors.white, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Tag(
                      text:
                          '${stats.okDevices} ${isAr ? 'سليم' : 'Healthy'}',
                      color: _DT.green,
                    ),
                    _Tag(
                      text:
                          '${stats.maintenanceDevices} ${isAr ? 'صيانة' : 'Maint.'}',
                      color: _DT.amber,
                    ),
                    _Tag(
                      text:
                          '${stats.outOfServiceDevices} ${isAr ? 'خارج الخدمة' : 'Out'}',
                      color: _DT.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 240.ms).fadeIn().slideY(begin: 0.05);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UTILITY WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

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

  const _ErrorCard({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isAr = AppLocalizations.of(context).isAr;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DT.redLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DT.red.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline_rounded, color: _DT.red, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: _DT.caption.copyWith(color: _DT.red),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _DT.red,
                  side: BorderSide(color: _DT.red.withOpacity(0.4)),
                ),
              ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DT.c200),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 32, color: _DT.c400),
          const SizedBox(height: 8),
          Text(
            label,
            style: _DT.body,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

String _timeAgo(DateTime dt, bool isAr) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return isAr ? 'الآن' : 'Just now';
  if (diff.inMinutes < 60) {
    return isAr ? 'منذ ${diff.inMinutes} د' : '${diff.inMinutes}m ago';
  }
  if (diff.inHours < 24) {
    return isAr ? 'منذ ${diff.inHours} س' : '${diff.inHours}h ago';
  }
  return isAr ? 'منذ ${diff.inDays} ي' : '${diff.inDays}d ago';
}
