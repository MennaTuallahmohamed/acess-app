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

// ─────────────────────────────────────────────
// Design Tokens (same palette as analytics screen)
// ─────────────────────────────────────────────
class _C {
  static const bg = Color(0xFFF0F4FF);
  static const card = Colors.white;
  static const cardAlt = Color(0xFFF8FAFF);

  static const navy = Color(0xFF1A237E);
  static const navyMid = Color(0xFF283593);
  static const navyLight = Color(0xFFE8EAF6);
  static const violet = Color(0xFF7C3AED);
  static const violetLight = Color(0xFFEDE9FE);

  static const green = Color(0xFF16A34A);
  static const greenLight = Color(0xFFDCFCE7);
  static const amber = Color(0xFFF59E0B);
  static const amberLight = Color(0xFFFEF3C7);
  static const red = Color(0xFFDC2626);
  static const redLight = Color(0xFFFEE2E2);
  static const blue = Color(0xFF0284C7);
  static const blueLight = Color(0xFFE0F2FE);
  static const teal = Color(0xFF0F766E);
  static const tealLight = Color(0xFFCCFBF1);

  static const text = Color(0xFF0F172A);
  static const textMid = Color(0xFF334155);
  static const textSub = Color(0xFF64748B);
  static const textHint = Color(0xFF94A3B8);

  static const border = Color(0xFFE2E8F0);
  static const borderLight = Color(0xFFF1F5F9);
}

BoxDecoration _card({Color? accent}) => BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: accent != null ? accent.withOpacity(0.18) : _C.border),
      boxShadow: [
        BoxShadow(
          color: (accent ?? _C.navy).withOpacity(0.06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );

// ─────────────────────────────────────────────
// Main Dashboard Screen
// ─────────────────────────────────────────────
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
      backgroundColor: _C.bg,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            elevation: 0,
            backgroundColor: _C.navy,
            leading: _AppBarBtn(icon: Icons.logout_rounded, onTap: onLogout),
            actions: [
              _AppBarBtn(
                icon: Icons.refresh_rounded,
                onTap: () {
                  ref.invalidate(adminStatsProvider);
                  ref.invalidate(allTasksProvider);
                  ref.invalidate(techniciansProvider);
                  ref.invalidate(adminDevicesProvider(null));
                  ref.invalidate(adminAnalyticsProvider);
                },
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
                    l.isAr ? 'لوحة المتابعة' : 'Operations Home',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    adminName,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0D1B6E), Color(0xFF1A237E), Color(0xFF4527A0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                  // Decorative circles
                  Positioned(
                    right: -25,
                    top: -30,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 40,
                    top: 10,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _C.violet.withOpacity(0.18),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    bottom: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.04),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Section
                  _DashSection(
                    title: l.isAr ? 'الملخص العام' : 'General Summary',
                    icon: Icons.insights_rounded,
                  ).animate().fadeIn().slideY(begin: 0.06),
                  const SizedBox(height: 14),
                  stats.when(
                    loading: () => const _Shimmer(count: 2),
                    error: (e, _) => _ErrCard(message: e.toString(), onRetry: () => ref.invalidate(adminStatsProvider)),
                    data: (s) => _StatsGrid(stats: s, isAr: l.isAr),
                  ).animate(delay: 60.ms).fadeIn(),

                  const SizedBox(height: 28),

                  // Operations Pulse
                  _DashSection(
                    title: l.isAr ? 'نبض التشغيل' : 'Operations Pulse',
                    icon: Icons.motion_photos_on_rounded,
                    actionLabel: l.isAr ? 'كل المهام' : 'All Tasks',
                    onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTasksScreen())),
                  ).animate(delay: 100.ms).fadeIn(),
                  const SizedBox(height: 14),
                  _PulseBlock(
                    isAr: l.isAr,
                    tasks: tasks,
                    technicians: technicians,
                    devices: devices,
                    onTaskTap: (task) => _openTask(context, task),
                  ).animate(delay: 160.ms).fadeIn(),

                  const SizedBox(height: 28),

                  // Analytics
                  _DashSection(
                    title: l.isAr ? 'التحليلات المتقدمة' : 'Advanced Analytics',
                    icon: Icons.auto_graph_rounded,
                    actionLabel: l.isAr ? 'المزيد' : 'More',
                    onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen())),
                  ).animate(delay: 200.ms).fadeIn(),
                  const SizedBox(height: 16),
                  analytics.when(
                    loading: () => const _Shimmer(count: 4),
                    error: (e, _) => _ErrCard(message: e.toString(), onRetry: () => ref.invalidate(adminAnalyticsProvider)),
                    data: (a) => _AnalyticsBlock(analytics: a, isAr: l.isAr),
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

  void _openTask(BuildContext context, TaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskDetailSheet(task: task, isViewer: false),
    );
  }
}

// ─────────────────────────────────────────────
// App bar button
// ─────────────────────────────────────────────
class _AppBarBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AppBarBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────
class _DashSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _DashSection({required this.title, required this.icon, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: _C.navyLight, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _C.navy, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: _C.text,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _C.navyLight,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _C.navy.withOpacity(0.18)),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: _C.navy,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Stats Grid
// ─────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final AdminStats stats;
  final bool isAr;
  const _StatsGrid({required this.stats, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(isAr ? 'الفنيون' : 'Technicians', stats.totalTechnicians.toString(),
          Icons.people_rounded, _C.navy, _C.navyLight),
      _StatItem(isAr ? 'الأجهزة' : 'Devices', stats.totalDevices.toString(),
          Icons.devices_rounded, _C.violet, _C.violetLight),
      _StatItem(isAr ? 'مهام مكتملة' : 'Completed', stats.completedTasks.toString(),
          Icons.task_alt_rounded, _C.green, _C.greenLight),
      _StatItem(isAr ? 'تقارير مفتوحة' : 'Open Reports', stats.openReports.toString(),
          Icons.assignment_late_rounded, _C.amber, _C.amberLight),
    ];

    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth < 700 ? (c.maxWidth - 10) / 2 : (c.maxWidth - 30) / 4;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items.asMap().entries.map((entry) {
          return SizedBox(
            width: w,
            child: _StatCard(item: entry.value)
                .animate(delay: (entry.key * 60).ms)
                .fadeIn(duration: 250.ms)
                .slideY(begin: 0.06),
          );
        }).toList(),
      );
    });
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
  const _StatItem(this.label, this.value, this.icon, this.color, this.bg);
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(accent: item.color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: item.bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            item.value,
            style: TextStyle(
              color: item.color,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w900,
              fontSize: 26,
              letterSpacing: -0.5,
            ),
          ),
          Text(item.label,
              style: const TextStyle(color: _C.textSub, fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Pulse block
// ─────────────────────────────────────────────
class _PulseBlock extends StatelessWidget {
  final bool isAr;
  final AsyncValue<List<TaskModel>> tasks;
  final AsyncValue<List<TechnicianModel>> technicians;
  final AsyncValue<List<AdminDeviceModel>> devices;
  final ValueChanged<TaskModel> onTaskTap;

  const _PulseBlock({
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
      error: (e, _) => _ErrCard(message: e.toString()),
      data: (taskList) => technicians.when(
        loading: () => const AdminShimmerList(count: 3),
        error: (e, _) => _ErrCard(message: e.toString()),
        data: (techList) => devices.when(
          loading: () => const AdminShimmerList(count: 3),
          error: (e, _) => _ErrCard(message: e.toString()),
          data: (deviceList) => _PulseContent(
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

class _PulseContent extends StatelessWidget {
  final bool isAr;
  final List<TaskModel> tasks;
  final List<TechnicianModel> technicians;
  final List<AdminDeviceModel> devices;
  final ValueChanged<TaskModel> onTaskTap;

  const _PulseContent({
    required this.isAr,
    required this.tasks,
    required this.technicians,
    required this.devices,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final sortedTasks = [...tasks]..sort((a, b) => _moment(b).compareTo(_moment(a)));
    final latestTask = sortedTasks.isEmpty ? null : sortedTasks.first;

    final sortedTechs = technicians.where((t) => t.lastActivity != null).toList()
      ..sort((a, b) => b.lastActivity!.compareTo(a.lastActivity!));
    final latestTech = sortedTechs.isEmpty ? null : sortedTechs.first;

    final sortedDevices = devices.where((d) => d.lastInspectionAt != null).toList()
      ..sort((a, b) => b.lastInspectionAt!.compareTo(a.lastInspectionAt!));
    final latestDevice = sortedDevices.isEmpty ? null : sortedDevices.first;

    final activeTasks = tasks.where((t) => t.status == 'PENDING' || t.status == 'IN_PROGRESS').length;

    return Column(
      children: [
        // ── Pulse Hero ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0C2149), Color(0xFF173B78), Color(0xFF1E5AA7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: _C.navy.withOpacity(0.28), blurRadius: 24, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .scaleXY(begin: 1, end: 1.4, duration: 800.ms)
                      .then()
                      .scaleXY(begin: 1.4, end: 1, duration: 800.ms),
                  const SizedBox(width: 8),
                  Text(
                    isAr ? 'آخر حركة على النظام' : 'Latest system movement',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white.withOpacity(0.65)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                latestTask == null
                    ? (isAr ? 'لا توجد أنشطة حديثة بعد' : 'No recent activity yet')
                    : _taskHeadline(latestTask, isAr),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  height: 1.3,
                  letterSpacing: -0.2,
                ),
              ),
              if (latestTask != null) ...[
                const SizedBox(height: 4),
                Text(
                  _taskSubhead(latestTask, isAr),
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white.withOpacity(0.60), height: 1.4),
                ),
              ],
              const SizedBox(height: 16),
              LayoutBuilder(builder: (context, c) {
                final compact = c.maxWidth < 640;
                final cards = [
                  _MiniPulse(
                    icon: Icons.playlist_play_rounded,
                    title: isAr ? 'المهام النشطة' : 'Active Tasks',
                    value: '$activeTasks',
                    sub: isAr ? 'قيد المتابعة' : 'being tracked',
                    color: const Color(0xFF93C5FD),
                  ),
                  _MiniPulse(
                    icon: Icons.person_pin_circle_rounded,
                    title: isAr ? 'آخر فني' : 'Latest Tech',
                    value: latestTech?.fullName ?? (isAr ? 'لا يوجد' : 'None'),
                    sub: latestTech?.lastActivity == null
                        ? (isAr ? 'لا نشاط' : 'No activity')
                        : _timeAgo(latestTech!.lastActivity!, isAr),
                    color: const Color(0xFF6EE7B7),
                  ),
                  _MiniPulse(
                    icon: Icons.devices_fold_rounded,
                    title: isAr ? 'آخر جهاز' : 'Latest Device',
                    value: latestDevice?.name ?? (isAr ? 'لا يوجد' : 'None'),
                    sub: latestDevice?.lastInspectionAt == null
                        ? (isAr ? 'بدون فحص' : 'No inspection')
                        : _timeAgo(latestDevice!.lastInspectionAt!, isAr),
                    color: const Color(0xFFFDE68A),
                  ),
                ];

                if (compact) {
                  return Column(
                    children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: c)).toList(),
                  );
                }
                return Row(
                  children: cards
                      .asMap()
                      .entries
                      .map((e) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: e.key > 0 ? 8 : 0),
                              child: e.value,
                            ),
                          ))
                      .toList(),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Recent Tasks ──
        if (sortedTasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: _card(),
            child: Text(
              isAr ? 'لا توجد مهام لعرض آخر النشاط' : 'No tasks to build activity from',
              style: const TextStyle(fontFamily: 'Cairo', color: _C.textSub),
            ),
          )
        else
          ...sortedTasks.take(3).map((task) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ActivityTile(task: task, isAr: isAr, onTap: () => onTaskTap(task)),
            );
          }),
      ],
    );
  }

  static DateTime _moment(TaskModel task) => task.completedAt ?? task.createdAt;

  static String _taskHeadline(TaskModel task, bool isAr) {
    final action = switch (task.status) {
      'COMPLETED' => isAr ? 'اكتملت المهمة الأخيرة' : 'Latest completion recorded',
      'IN_PROGRESS' => isAr ? 'هناك متابعة جارية الآن' : 'Active follow-up in progress',
      _ => isAr ? 'تم إنشاء متابعة جديدة' : 'New follow-up was created',
    };
    return '$action${task.deviceName != null ? (isAr ? ' على ${task.deviceName}' : ' on ${task.deviceName}') : ''}';
  }

  static String _taskSubhead(TaskModel task, bool isAr) {
    final tech = task.assignedToName ?? (isAr ? 'فني غير محدد' : 'Unassigned');
    final place = task.locationName ?? task.deviceCode ?? '';
    if (place.isEmpty) return isAr ? 'مسندة إلى $tech' : 'Assigned to $tech';
    return isAr ? 'مسندة إلى $tech في $place' : 'Assigned to $tech at $place';
  }
}

// ─────────────────────────────────────────────
// Mini Pulse card
// ─────────────────────────────────────────────
class _MiniPulse extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String sub;
  final Color color;

  const _MiniPulse({required this.icon, required this.title, required this.value, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.white.withOpacity(0.65))),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.white, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.white.withOpacity(0.50))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Activity tile
// ─────────────────────────────────────────────
class _ActivityTile extends StatelessWidget {
  final TaskModel task;
  final bool isAr;
  final VoidCallback onTap;

  const _ActivityTile({required this.task, required this.isAr, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = switch (task.status) {
      'COMPLETED' => _C.green,
      'IN_PROGRESS' => _C.blue,
      'OVERDUE' => _C.red,
      _ => _C.amber,
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
            border: Border.all(color: color.withOpacity(0.16)),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.bolt_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 13, color: _C.text),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      task.deviceName != null
                          ? (isAr ? 'على ${task.deviceName}' : 'On ${task.deviceName}')
                          : (isAr ? 'بدون جهاز محدد' : 'No linked device'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: _C.textSub),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Tag(
                          text: task.assignedToName ?? (isAr ? 'بدون فني' : 'Unassigned'),
                          color: _C.navy,
                        ),
                        _Tag(
                          text: isAr ? task.statusAr : task.statusEn,
                          color: color,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _timeAgo(task.completedAt ?? task.createdAt, isAr),
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 10, color: _C.textHint, fontWeight: FontWeight.w700),
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Analytics block
// ─────────────────────────────────────────────
class _AnalyticsBlock extends StatelessWidget {
  final AdminAnalyticsData analytics;
  final bool isAr;
  const _AnalyticsBlock({required this.analytics, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final s = analytics.stats;
    final totalDevices = s.totalDevices == 0 ? 1 : s.totalDevices;
    final healthyRate = ((s.okDevices / totalDevices) * 100).round();

    return Column(
      children: [
        // Efficiency Hero
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF283593)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: _C.navy.withOpacity(0.25), blurRadius: 22, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'جاهزية الأجهزة' : 'Device Readiness',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white.withOpacity(0.65)),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$healthyRate',
                    style: const TextStyle(
                        fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.w900, fontSize: 52, letterSpacing: -2),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('%',
                        style: TextStyle(fontFamily: 'Cairo', color: Colors.white.withOpacity(0.70), fontWeight: FontWeight.w800, fontSize: 20)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _GlassPill(
                      text: '${s.okDevices} ${isAr ? 'سليم' : 'Healthy'}',
                      color: const Color(0xFF86EFAC)),
                  _GlassPill(
                      text: '${s.maintenanceDevices} ${isAr ? 'صيانة' : 'Maintenance'}',
                      color: const Color(0xFFFDE68A)),
                  _GlassPill(
                      text: '${s.outOfServiceDevices} ${isAr ? 'خارج الخدمة' : 'Out of service'}',
                      color: const Color(0xFFFCA5A5)),
                ],
              ),
            ],
          ),
        ).animate(delay: 240.ms).fadeIn().slideY(begin: 0.05),

        const SizedBox(height: 14),

        // Chart cards
        ...[
          _ChartCard(
            title: isAr ? 'حالة الأجهزة' : 'Device Health Status',
            sub: isAr ? 'توزيع حالة الأجهزة' : 'Current device status',
            icon: Icons.pie_chart_rounded,
            child: DeviceStatusDonutChart(data: analytics.deviceStatus),
          ),
          _ChartCard(
            title: isAr ? 'حالة المهام' : 'Task Status',
            sub: isAr ? 'توزيع المهام حسب الحالة' : 'Tasks by status',
            icon: Icons.donut_large_rounded,
            child: TaskStatusDonutChart(data: analytics.taskStatus),
          ),
          _ChartCard(
            title: isAr ? 'الأجهزة حسب المباني' : 'Devices by Building',
            sub: isAr ? 'أكثر المباني احتواءً للأجهزة' : 'Top buildings by devices',
            icon: Icons.apartment_rounded,
            child: DevicesByBuildingBarChart(data: analytics.devicesByBuilding),
          ),
          _ChartCard(
            title: isAr ? 'الأجهزة حسب النوع' : 'Devices by Type',
            sub: isAr ? 'توزيع الأجهزة حسب النوع' : 'Device type distribution',
            icon: Icons.category_rounded,
            child: DevicesByTypeBarChart(data: analytics.devicesByType),
          ),
          _ChartCard(
            title: isAr ? 'اتجاه إنجاز المهام' : 'Task Completion Trend',
            sub: isAr ? 'آخر 7 أيام' : 'Last 7 days',
            icon: Icons.show_chart_rounded,
            child: TaskCompletionTrendChart(data: analytics.taskCompletionTrend),
          ),
          _ChartCard(
            title: isAr ? 'أداء الفنيين' : 'Technician Performance',
            sub: isAr ? 'أفضل الفنيين بالنشاط' : 'Top technicians by activity',
            icon: Icons.groups_rounded,
            child: TechnicianPerformanceBarChart(data: analytics.technicianPerformance),
          ),
          _ChartCard(
            title: isAr ? 'التفتيشات عبر الزمن' : 'Inspections Over Time',
            sub: isAr ? 'آخر 7 أيام' : 'Last 7 days',
            icon: Icons.timeline_rounded,
            child: InspectionsOverTimeChart(data: analytics.inspectionsOverTime),
          ),
          _ChartCard(
            title: isAr ? 'تنفيذ المهام لكل فني' : 'Task Execution by Technician',
            sub: isAr ? 'مكتمل وجارٍ ومعلّق' : 'Completed vs in progress vs pending',
            icon: Icons.bar_chart_rounded,
            child: TaskExecutionStackedChart(data: analytics.taskExecutionByTechnician),
          ),
        ]
            .asMap()
            .entries
            .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: e.value.animate(delay: (260 + e.key * 40).ms).fadeIn(duration: 280.ms).slideY(begin: 0.05),
                ))
            .toList(),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Chart Card shell
// ─────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title;
  final String sub;
  final IconData icon;
  final Widget child;

  const _ChartCard({required this.title, required this.sub, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: _C.navyLight, borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, color: _C.navy, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 14, color: _C.text)),
                    Text(sub,
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: _C.textSub)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Reusable small widgets
// ─────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(999)),
      child: Text(text,
          style: TextStyle(color: color, fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final String text;
  final Color color;
  const _GlassPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

// ─────────────────────────────────────────────
// Loading & Error
// ─────────────────────────────────────────────
class _Shimmer extends StatelessWidget {
  final int count;
  const _Shimmer({required this.count});

  @override
  Widget build(BuildContext context) => AdminShimmerList(count: count);
}

class _ErrCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _ErrCard({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.redLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.red.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(color: _C.red, fontFamily: 'Cairo')),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: Text(AppLocalizations.of(context).isAr ? 'إعادة المحاولة' : 'Retry'),
              style: OutlinedButton.styleFrom(foregroundColor: _C.red),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────
String _timeAgo(DateTime dt, bool isAr) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) {
    return isAr ? 'منذ ${diff.inMinutes} دقيقة' : '${diff.inMinutes}m ago';
  }
  if (diff.inHours < 24) {
    return isAr ? 'منذ ${diff.inHours} ساعة' : '${diff.inHours}h ago';
  }
  return isAr ? 'منذ ${diff.inDays} يوم' : '${diff.inDays}d ago';
}