import 'dart:math' as math;

import 'package:access_track/admin/admin_models.dart';
import 'package:access_track/admin/admin_providers.dart';
import 'package:access_track/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS (shared with dashboard)
// ─────────────────────────────────────────────────────────────────────────────

class _DT {
  static const gradientHeader = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF4C1D95)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const shadowCard = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 14,
      offset: Offset(0, 5),
    ),
  ];

  static const c50 = Color(0xFFF8FAFC);
  static const c100 = Color(0xFFF1F5F9);
  static const c200 = Color(0xFFE2E8F0);
  static const c400 = Color(0xFF94A3B8);
  static const c600 = Color(0xFF475569);
  static const c900 = Color(0xFF0F172A);

  static const blue = Color(0xFF1A237E);
  static const blueLight = Color(0xFFE8EAF6);
  static const green = Color(0xFF16A34A);
  static const greenLight = Color(0xFFD1FAE5);
  static const amber = Color(0xFFF59E0B);
  static const amberLight = Color(0xFFFEF3C7);
  static const red = Color(0xFFDC2626);
  static const redLight = Color(0xFFFEE2E2);
  static const cyan = Color(0xFF0284C7);
  static const teal = Color(0xFF0F766E);
  static const violet = Color(0xFF7C3AED);

  static const _base = TextStyle(fontFamily: 'Cairo');
  static final h1 = _base.copyWith(
      fontSize: 28, fontWeight: FontWeight.w900, color: c900);
  static final h2 = _base.copyWith(
      fontSize: 20, fontWeight: FontWeight.w900, color: c900);
  static final h3 = _base.copyWith(
      fontSize: 16, fontWeight: FontWeight.w800, color: c900);
  static final body = _base.copyWith(
      fontSize: 13, fontWeight: FontWeight.w600, color: c600);
  static final bodyBold = _base.copyWith(
      fontSize: 13, fontWeight: FontWeight.w800, color: c900);
  static final caption = _base.copyWith(
      fontSize: 11, fontWeight: FontWeight.w600, color: c400);
  static final captionBold = _base.copyWith(
      fontSize: 11, fontWeight: FontWeight.w800, color: c400);
  static final micro = _base.copyWith(
      fontSize: 9.5, fontWeight: FontWeight.w700, color: c400);
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = AppLocalizations.of(context).isAr;

    final tasksAsync = ref.watch(allTasksProvider);
    final techsAsync = ref.watch(activeTechniciansProvider);
    final devicesAsync = ref.watch(adminDevicesProvider(null));
    final inspectionsAsync = ref.watch(monthlyInspectionsProvider);

    void refresh() {
      ref.invalidate(allTasksProvider);
      ref.invalidate(activeTechniciansProvider);
      ref.invalidate(techniciansProvider);
      ref.invalidate(adminDevicesProvider(null));
      ref.invalidate(monthlyInspectionsProvider);
      ref.invalidate(adminStatsProvider);
      ref.invalidate(adminAnalyticsProvider);
    }

    final loading = tasksAsync.isLoading ||
        techsAsync.isLoading ||
        devicesAsync.isLoading ||
        inspectionsAsync.isLoading;

    final error = tasksAsync.error ??
        techsAsync.error ??
        devicesAsync.error ??
        inspectionsAsync.error;

    Widget body;

    if (loading) {
      body = const _LoadingView();
    } else if (error != null) {
      body = _ErrorView(message: error.toString(), onRetry: refresh);
    } else {
      final data = _AnalyticsData.fromRaw(
        tasks: tasksAsync.valueOrNull ?? const [],
        technicians: techsAsync.valueOrNull ?? const [],
        devices: devicesAsync.valueOrNull ?? const [],
        inspections: inspectionsAsync.valueOrNull ?? const [],
      );

      body = DefaultTabController(
        length: 5,
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: _Header(
                isAr: isAr,
                data: data,
                onBack: () => _goBack(context, ref),
                onRefresh: refresh,
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabsHeaderDelegate(
                child: _TabBar(isAr: isAr),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _OverviewTab(data: data, isAr: isAr),
              _DevicesTab(data: data, isAr: isAr),
              _TechniciansTab(data: data, isAr: isAr),
              _TrendsTab(data: data, isAr: isAr),
              _ActivityTab(data: data, isAr: isAr),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _DT.c50,
      body: SafeArea(bottom: false, child: body),
    );
  }

  static void _goBack(BuildContext context, WidgetRef ref) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      ref.read(adminPageIndexProvider.notifier).state = 0;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

class _AnalyticsData {
  final List<TaskModel> tasks;
  final List<TechnicianModel> technicians;
  final List<AdminDeviceModel> devices;
  final List<InspectionDetail> inspections;

  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int inProgressTasks;
  final int overdueTasks;
  final int urgentTasks;
  final int cancelledTasks;

  final int totalDevices;
  final int okDevices;
  final int maintenanceDevices;
  final int outDevices;
  final int otherDevices;

  final int totalTechnicians;
  final int totalInspections;
  final int okInspections;
  final int notOkInspections;
  final int partialInspections;
  final int unreachableInspections;

  final double completionRate;
  final double deviceHealthRate;
  final double inspectionOkRate;
  final int overallScore;

  final List<_LegendDatum> taskStatus;
  final List<_LegendDatum> deviceStatus;
  final List<_LegendDatum> inspectionStatus;
  final List<_BarDatum> tasksByTechnician;
  final List<_BarDatum> inspectionsByTechnician;
  final List<_StackDatum> executionByTechnician;
  final List<_LineDatum> taskTrend;
  final List<_LineDatum> inspectionTrend;
  final List<_ActivityItem> activity;

  const _AnalyticsData({
    required this.tasks,
    required this.technicians,
    required this.devices,
    required this.inspections,
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.inProgressTasks,
    required this.overdueTasks,
    required this.urgentTasks,
    required this.cancelledTasks,
    required this.totalDevices,
    required this.okDevices,
    required this.maintenanceDevices,
    required this.outDevices,
    required this.otherDevices,
    required this.totalTechnicians,
    required this.totalInspections,
    required this.okInspections,
    required this.notOkInspections,
    required this.partialInspections,
    required this.unreachableInspections,
    required this.completionRate,
    required this.deviceHealthRate,
    required this.inspectionOkRate,
    required this.overallScore,
    required this.taskStatus,
    required this.deviceStatus,
    required this.inspectionStatus,
    required this.tasksByTechnician,
    required this.inspectionsByTechnician,
    required this.executionByTechnician,
    required this.taskTrend,
    required this.inspectionTrend,
    required this.activity,
  });

  factory _AnalyticsData.fromRaw({
    required List<TaskModel> tasks,
    required List<TechnicianModel> technicians,
    required List<AdminDeviceModel> devices,
    required List<InspectionDetail> inspections,
  }) {
    final completedTasks =
        tasks.where((t) => _norm(t.status) == 'COMPLETED').length;
    final pendingTasks =
        tasks.where((t) => _norm(t.status) == 'PENDING').length;
    final inProgressTasks =
        tasks.where((t) => _norm(t.status) == 'IN_PROGRESS').length;
    final overdueTasks =
        tasks.where((t) => _norm(t.status) == 'OVERDUE').length;
    final cancelledTasks =
        tasks.where((t) => _norm(t.status) == 'CANCELLED').length;
    final urgentTasks = tasks.where((t) {
      final status = _norm(t.status);
      final priority = _norm(t.priority);
      return t.isUrgent ||
          t.isEmergency ||
          status == 'URGENT' ||
          priority == 'URGENT';
    }).length;

    final okDevices =
        devices.where((d) => _isOkDevice(d.currentStatus)).length;
    final maintenanceDevices =
        devices.where((d) => _isMaintenanceDevice(d.currentStatus)).length;
    final outDevices =
        devices.where((d) => _isFaultDevice(d.currentStatus)).length;
    final otherDevices = math.max(
        devices.length - okDevices - maintenanceDevices - outDevices, 0);

    final okInspections =
        inspections.where((i) => _norm(i.inspectionStatus) == 'OK').length;
    final notOkInspections =
        inspections.where((i) => _norm(i.inspectionStatus) == 'NOT_OK').length;
    final partialInspections =
        inspections.where((i) => _norm(i.inspectionStatus) == 'PARTIAL').length;
    final unreachableInspections = inspections
        .where((i) => _norm(i.inspectionStatus) == 'NOT_REACHABLE')
        .length;

    final tasksByTechnicianMap = <String, int>{};
    final inspectionsByTechnicianMap = <String, int>{};
    final pendingByTech = <String, double>{};
    final progressByTech = <String, double>{};
    final completedByTech = <String, double>{};

    for (final task in tasks) {
      final name = _safeLabel(task.assignedToName, fallback: 'Unassigned');
      tasksByTechnicianMap[name] = (tasksByTechnicianMap[name] ?? 0) + 1;
      final status = _norm(task.status);
      if (status == 'COMPLETED') {
        completedByTech[name] = (completedByTech[name] ?? 0) + 1;
      } else if (status == 'IN_PROGRESS') {
        progressByTech[name] = (progressByTech[name] ?? 0) + 1;
      } else {
        pendingByTech[name] = (pendingByTech[name] ?? 0) + 1;
      }
    }

    for (final inspection in inspections) {
      final name =
          _safeLabel(inspection.technicianName, fallback: 'Unknown');
      inspectionsByTechnicianMap[name] =
          (inspectionsByTechnicianMap[name] ?? 0) + 1;
    }

    final techNames = <String>{
      ...pendingByTech.keys,
      ...progressByTech.keys,
      ...completedByTech.keys,
    };

    final executionByTechnician = techNames
        .map((name) => _StackDatum(
              name,
              pending: pendingByTech[name] ?? 0,
              inProgress: progressByTech[name] ?? 0,
              completed: completedByTech[name] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    final totalTasks = tasks.length;
    final totalDevices = devices.length;
    final totalInspections = inspections.length;
    final completionRate =
        totalTasks == 0 ? 0.0 : completedTasks / totalTasks * 100;
    final deviceHealthRate =
        totalDevices == 0 ? 0.0 : okDevices / totalDevices * 100;
    final inspectionOkRate =
        totalInspections == 0 ? 0.0 : okInspections / totalInspections * 100;
    final overallScore =
        ((completionRate * 0.45) + (deviceHealthRate * 0.35) + (inspectionOkRate * 0.20))
            .round()
            .clamp(0, 100);

    return _AnalyticsData(
      tasks: tasks,
      technicians: technicians,
      devices: devices,
      inspections: inspections,
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      pendingTasks: pendingTasks,
      inProgressTasks: inProgressTasks,
      overdueTasks: overdueTasks,
      urgentTasks: urgentTasks,
      cancelledTasks: cancelledTasks,
      totalDevices: totalDevices,
      okDevices: okDevices,
      maintenanceDevices: maintenanceDevices,
      outDevices: outDevices,
      otherDevices: otherDevices,
      totalTechnicians: technicians.length,
      totalInspections: totalInspections,
      okInspections: okInspections,
      notOkInspections: notOkInspections,
      partialInspections: partialInspections,
      unreachableInspections: unreachableInspections,
      completionRate: completionRate,
      deviceHealthRate: deviceHealthRate,
      inspectionOkRate: inspectionOkRate,
      overallScore: overallScore,
      taskStatus: [
        _LegendDatum('PENDING', pendingTasks),
        _LegendDatum('IN_PROGRESS', inProgressTasks),
        _LegendDatum('COMPLETED', completedTasks),
        _LegendDatum('OVERDUE', overdueTasks),
        _LegendDatum('URGENT', urgentTasks),
        _LegendDatum('CANCELLED', cancelledTasks),
      ],
      deviceStatus: [
        _LegendDatum('OK', okDevices),
        _LegendDatum('MAINTENANCE', maintenanceDevices),
        _LegendDatum('OUT_OF_SERVICE', outDevices),
        _LegendDatum('OTHER', otherDevices),
      ],
      inspectionStatus: [
        _LegendDatum('OK', okInspections),
        _LegendDatum('NOT_OK', notOkInspections),
        _LegendDatum('PARTIAL', partialInspections),
        _LegendDatum('NOT_REACHABLE', unreachableInspections),
      ],
      tasksByTechnician: _barList(tasksByTechnicianMap),
      inspectionsByTechnician: _barList(inspectionsByTechnicianMap),
      executionByTechnician: executionByTechnician,
      taskTrend: _lastDaysTrendFromTasks(tasks, 14),
      inspectionTrend: _lastDaysTrendFromInspections(inspections, 14),
      activity: _buildActivity(tasks, inspections),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA TYPES
// ─────────────────────────────────────────────────────────────────────────────

class _LegendDatum {
  final String label;
  final int value;
  const _LegendDatum(this.label, this.value);
}

class _BarDatum {
  final String label;
  final double value;
  const _BarDatum(this.label, this.value);
}

class _LineDatum {
  final String label;
  final double value;
  const _LineDatum(this.label, this.value);
}

class _StackDatum {
  final String label;
  final double pending;
  final double inProgress;
  final double completed;

  const _StackDatum(this.label,
      {required this.pending,
      required this.inProgress,
      required this.completed});

  double get total => pending + inProgress + completed;
}

class _ActivityItem {
  final String title;
  final String subtitle;
  final DateTime date;
  final IconData icon;
  final Color color;
  final String type;

  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.icon,
    required this.color,
    required this.type,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool isAr;
  final _AnalyticsData data;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _Header({
    required this.isAr,
    required this.data,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      decoration: const BoxDecoration(gradient: _DT.gradientHeader),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            children: [
              _HeaderBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
              const SizedBox(width: 10),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: const Icon(Icons.analytics_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'تحليلات النظام' : 'System Analytics',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isAr
                          ? 'كل الأرقام من الباك إند مباشرة'
                          : 'Live data from backend',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontFamily: 'Cairo',
                        fontSize: 10.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _HeaderBtn(icon: Icons.refresh_rounded, onTap: onRefresh),
            ],
          ),
          const SizedBox(height: 16),
          // Stats chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _HeaderChip(
                label: isAr
                    ? '${data.totalTasks} مهمة'
                    : '${data.totalTasks} tasks',
                icon: Icons.assignment_rounded,
              ),
              _HeaderChip(
                label: isAr
                    ? '${data.totalDevices} جهاز'
                    : '${data.totalDevices} devices',
                icon: Icons.devices_rounded,
              ),
              _HeaderChip(
                label: isAr
                    ? '${data.totalInspections} تفتيش'
                    : '${data.totalInspections} checks',
                icon: Icons.fact_check_rounded,
              ),
              _ScoreChip(score: data.overallScore, isAr: isAr),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _HeaderChip({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 11),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final int score;
  final bool isAr;

  const _ScoreChip({required this.score, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final color = score >= 75
        ? const Color(0xFF4ADE80)
        : score >= 50
            ? const Color(0xFFFCD34D)
            : const Color(0xFFF87171);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            isAr ? '$score% أداء' : '$score% score',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB BAR
// ─────────────────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final bool isAr;
  const _TabBar({required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _DT.c50,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _DT.c200),
          boxShadow: _DT.shadowCard,
        ),
        child: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            gradient: _DT.gradientHeader,
            borderRadius: BorderRadius.circular(10),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: _DT.c600,
          labelStyle: const TextStyle(
              fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 11),
          unselectedLabelStyle: const TextStyle(
              fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 11),
          tabs: [
            Tab(text: isAr ? 'عام' : 'Overview'),
            Tab(text: isAr ? 'الأجهزة' : 'Devices'),
            Tab(text: isAr ? 'الفنيين' : 'Techs'),
            Tab(text: isAr ? 'الاتجاهات' : 'Trends'),
            Tab(text: isAr ? 'النشاط' : 'Activity'),
          ],
        ),
      ),
    );
  }
}

class _TabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _TabsHeaderDelegate({required this.child});

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  bool shouldRebuild(covariant _TabsHeaderDelegate oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB VIEWS
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final _AnalyticsData data;
  final bool isAr;

  const _OverviewTab({required this.data, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 110),
      children: [
        _HeroCard(data: data, isAr: isAr),
        const SizedBox(height: 14),
        _KpiGrid(data: data, isAr: isAr),
        const SizedBox(height: 18),
        _SectionTitle(title: isAr ? 'توزيع الحالات' : 'Status Distribution'),
        const SizedBox(height: 12),
        // Task & Device status side by side
        _TwoCol(
          first: _PieCard(
            title: isAr ? 'حالة المهام' : 'Task Status',
            icon: Icons.task_alt_rounded,
            data: data.taskStatus,
            labels: (v) => _taskLabel(v, isAr),
            colors: const [
              Color(0xFFF59E0B),
              Color(0xFF0284C7),
              Color(0xFF16A34A),
              Color(0xFFDC2626),
              Color(0xFF7C3AED),
              Color(0xFF64748B),
            ],
          ),
          second: _PieCard(
            title: isAr ? 'حالة الأجهزة' : 'Device Status',
            icon: Icons.devices_rounded,
            data: data.deviceStatus,
            labels: (v) => _deviceLabel(v, isAr),
            colors: const [
              Color(0xFF16A34A),
              Color(0xFFF59E0B),
              Color(0xFFDC2626),
              Color(0xFF64748B),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PieCard(
          title: isAr ? 'نتائج التفتيشات' : 'Inspection Results',
          icon: Icons.fact_check_rounded,
          data: data.inspectionStatus,
          labels: (v) => _inspectionLabel(v, isAr),
          colors: const [
            Color(0xFF16A34A),
            Color(0xFFDC2626),
            Color(0xFFF59E0B),
            Color(0xFF64748B),
          ],
        ),
      ],
    );
  }
}

class _DevicesTab extends StatelessWidget {
  final _AnalyticsData data;
  final bool isAr;

  const _DevicesTab({required this.data, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final total = data.totalDevices == 0 ? 1 : data.totalDevices;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 110),
      children: [
        _AnalysisHeader(
          title: isAr ? 'تحليل الأجهزة' : 'Device Analysis',
          subtitle: isAr
              ? 'من بيانات الأجهزة الحقيقية'
              : 'From real device records',
          icon: Icons.devices_other_rounded,
          color: _DT.blue,
          mainValue: '${data.deviceHealthRate.round()}%',
          mainLabel: isAr ? 'سليم' : 'Healthy',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _SmallStatCard(
                label: isAr ? 'سليم' : 'Healthy',
                value: data.okDevices.toString(),
                color: _DT.green,
                icon: Icons.check_circle_outline_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SmallStatCard(
                label: isAr ? 'صيانة' : 'Maint.',
                value: data.maintenanceDevices.toString(),
                color: _DT.amber,
                icon: Icons.build_circle_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SmallStatCard(
                label: isAr ? 'خارج' : 'Out',
                value: data.outDevices.toString(),
                color: _DT.red,
                icon: Icons.cancel_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _CardShell(
          title: isAr ? 'مقاييس الصحة' : 'Health Meters',
          icon: Icons.speed_rounded,
          child: Column(
            children: [
              _HealthBar(
                  label: isAr ? 'سليم' : 'Healthy',
                  value: data.okDevices / total,
                  count: data.okDevices,
                  color: _DT.green),
              const SizedBox(height: 12),
              _HealthBar(
                  label: isAr ? 'صيانة' : 'Maintenance',
                  value: data.maintenanceDevices / total,
                  count: data.maintenanceDevices,
                  color: _DT.amber),
              const SizedBox(height: 12),
              _HealthBar(
                  label: isAr ? 'خارج الخدمة' : 'Out of service',
                  value: data.outDevices / total,
                  count: data.outDevices,
                  color: _DT.red),
              if (data.otherDevices > 0) ...[
                const SizedBox(height: 12),
                _HealthBar(
                    label: isAr ? 'أخرى' : 'Other',
                    value: data.otherDevices / total,
                    count: data.otherDevices,
                    color: _DT.c400),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _PieCard(
          title: isAr ? 'نسب حالات الأجهزة' : 'Device Status %',
          icon: Icons.donut_large_rounded,
          data: data.deviceStatus,
          labels: (v) => _deviceLabel(v, isAr),
          colors: const [
            Color(0xFF16A34A),
            Color(0xFFF59E0B),
            Color(0xFFDC2626),
            Color(0xFF64748B),
          ],
        ),
      ],
    );
  }
}

class _TechniciansTab extends StatelessWidget {
  final _AnalyticsData data;
  final bool isAr;

  const _TechniciansTab({required this.data, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 110),
      children: [
        _AnalysisHeader(
          title: isAr ? 'تحليل الفنيين' : 'Technician Analysis',
          subtitle: isAr
              ? 'مهام وتفتيشات من البيانات الحقيقية'
              : 'Tasks and inspections from real data',
          icon: Icons.engineering_rounded,
          color: _DT.teal,
          mainValue: data.totalTechnicians.toString(),
          mainLabel: isAr ? 'فني نشط' : 'Active techs',
        ),
        const SizedBox(height: 14),
        _TwoCol(
          first: _SmallStatCard(
            label: isAr ? 'متوسط مهام / فني' : 'Avg tasks / tech',
            value: data.totalTechnicians == 0
                ? '0'
                : (data.totalTasks / data.totalTechnicians).toStringAsFixed(1),
            color: _DT.blue,
            icon: Icons.assignment_ind_rounded,
          ),
          second: _SmallStatCard(
            label: isAr ? 'متوسط فحص / فني' : 'Avg checks / tech',
            value: data.totalTechnicians == 0
                ? '0'
                : (data.totalInspections / data.totalTechnicians)
                    .toStringAsFixed(1),
            color: _DT.teal,
            icon: Icons.fact_check_rounded,
          ),
        ),
        const SizedBox(height: 14),
        _BarChartCard(
          title: isAr ? 'المهام حسب الفني' : 'Tasks by Technician',
          icon: Icons.leaderboard_rounded,
          data: data.tasksByTechnician,
          color: _DT.blue,
        ),
        const SizedBox(height: 14),
        _BarChartCard(
          title: isAr ? 'التفتيشات حسب الفني' : 'Inspections by Tech',
          icon: Icons.fact_check_rounded,
          data: data.inspectionsByTechnician,
          color: _DT.teal,
        ),
        const SizedBox(height: 14),
        _StackedBarCard(data: data.executionByTechnician, isAr: isAr),
      ],
    );
  }
}

class _TrendsTab extends StatelessWidget {
  final _AnalyticsData data;
  final bool isAr;

  const _TrendsTab({required this.data, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 110),
      children: [
        _AnalysisHeader(
          title: isAr ? 'الاتجاهات الزمنية' : 'Time Trends',
          subtitle: isAr ? 'آخر 14 يوم' : 'Last 14 days',
          icon: Icons.timeline_rounded,
          color: _DT.cyan,
          mainValue: data.totalInspections.toString(),
          mainLabel: isAr ? 'تفتيش' : 'checks',
        ),
        const SizedBox(height: 14),
        _CardShell(
          title: isAr ? 'اتجاه إنجاز المهام' : 'Task Completion Trend',
          icon: Icons.show_chart_rounded,
          child: _SimpleLineChart(
            data: data.taskTrend,
            color: _DT.green,
            height: 200,
          ),
        ),
        const SizedBox(height: 14),
        _CardShell(
          title: isAr ? 'التفتيشات عبر الزمن' : 'Inspections Over Time',
          icon: Icons.timeline_rounded,
          child: _SimpleLineChart(
            data: data.inspectionTrend,
            color: _DT.cyan,
            height: 200,
          ),
        ),
      ],
    );
  }
}

class _ActivityTab extends StatelessWidget {
  final _AnalyticsData data;
  final bool isAr;

  const _ActivityTab({required this.data, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 110),
      children: [
        _AnalysisHeader(
          title: isAr ? 'النشاط الأخير' : 'Recent Activity',
          subtitle: isAr
              ? 'آخر مهام وتفتيشات'
              : 'Latest tasks and inspections',
          icon: Icons.history_rounded,
          color: _DT.violet,
          mainValue: data.activity.length.toString(),
          mainLabel: isAr ? 'عنصر' : 'items',
        ),
        const SizedBox(height: 14),
        _CardShell(
          title: isAr ? 'سجل النشاط' : 'Activity Feed',
          icon: Icons.history_rounded,
          child: data.activity.isEmpty
              ? const _NoData()
              : Column(
                  children: data.activity
                      .map((item) => _ActivityRow(item: item, isAr: isAr))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO & KPI
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final _AnalyticsData data;
  final bool isAr;

  const _HeroCard({required this.data, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecor(),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score ring
              SizedBox(
                width: 108,
                height: 108,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: data.overallScore / 100,
                      strokeWidth: 9,
                      backgroundColor: _DT.c200,
                      valueColor: const AlwaysStoppedAnimation(_DT.blue),
                      strokeCap: StrokeCap.round,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${data.overallScore}%',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            color: _DT.blue,
                          ),
                        ),
                        Text(
                          isAr ? 'أداء' : 'Score',
                          style: _DT.micro,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'الأداء العام' : 'Overall Performance',
                      style: _DT.h3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr
                          ? 'محسوب من إنجاز المهام، سلامة الأجهزة، ونتائج التفتيشات.'
                          : 'From task completion, device health, and inspection results.',
                      style: _DT.caption,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Pill(
                          text:
                              '${data.completedTasks}/${data.totalTasks} ${isAr ? 'مهام' : 'tasks'}',
                          color: _DT.green,
                        ),
                        _Pill(
                          text:
                              '${data.okDevices}/${data.totalDevices} ${isAr ? 'أجهزة' : 'dev'}',
                          color: _DT.blue,
                        ),
                        _Pill(
                          text:
                              '${data.okInspections}/${data.totalInspections} ${isAr ? 'فحص' : 'OK'}',
                          color: _DT.violet,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bottom mini stats
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _DT.c50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _DT.c200),
            ),
            child: Row(
              children: [
                _MiniStat(
                    label: isAr ? 'إنجاز' : 'Completion',
                    value: '${data.completionRate.round()}%',
                    color: _DT.green),
                _Divider(),
                _MiniStat(
                    label: isAr ? 'صحة' : 'Health',
                    value: '${data.deviceHealthRate.round()}%',
                    color: _DT.blue),
                _Divider(),
                _MiniStat(
                    label: isAr ? 'فحص سليم' : 'OK Checks',
                    value: '${data.inspectionOkRate.round()}%',
                    color: _DT.violet),
                _Divider(),
                _MiniStat(
                    label: isAr ? 'متأخرة' : 'Overdue',
                    value: data.overdueTasks.toString(),
                    color: _DT.red),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04);
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: _DT.micro,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: _DT.c200);
}

class _KpiGrid extends StatelessWidget {
  final _AnalyticsData data;
  final bool isAr;

  const _KpiGrid({required this.data, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiItem(
          isAr ? 'كل المهام' : 'Total Tasks',
          data.totalTasks.toString(),
          Icons.assignment_rounded,
          _DT.blue,
          '${data.completionRate.round()}%'),
      _KpiItem(
          isAr ? 'مكتملة' : 'Completed',
          data.completedTasks.toString(),
          Icons.check_circle_rounded,
          _DT.green,
          isAr ? 'تم إنجازها' : 'Done'),
      _KpiItem(
          isAr ? 'قيد التنفيذ' : 'In Progress',
          data.inProgressTasks.toString(),
          Icons.pending_rounded,
          _DT.cyan,
          isAr ? 'جارية' : 'Active'),
      _KpiItem(
          isAr ? 'متأخرة' : 'Overdue',
          data.overdueTasks.toString(),
          Icons.alarm_rounded,
          _DT.red,
          isAr ? 'تحتاج متابعة' : 'Follow-up'),
      _KpiItem(
          isAr ? 'الأجهزة' : 'Devices',
          data.totalDevices.toString(),
          Icons.devices_rounded,
          _DT.violet,
          '${data.deviceHealthRate.round()}%'),
      _KpiItem(
          isAr ? 'الفنيين' : 'Technicians',
          data.totalTechnicians.toString(),
          Icons.engineering_rounded,
          _DT.teal,
          isAr ? 'نشطين' : 'Active'),
      _KpiItem(
          isAr ? 'التفتيشات' : 'Inspections',
          data.totalInspections.toString(),
          Icons.fact_check_rounded,
          const Color(0xFF6D28D9),
          '${data.inspectionOkRate.round()}%'),
      _KpiItem(
          isAr ? 'طارئة' : 'Urgent',
          data.urgentTasks.toString(),
          Icons.bolt_rounded,
          const Color(0xFFEA580C),
          isAr ? 'أولوية عالية' : 'High priority'),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: items
          .asMap()
          .entries
          .map((e) => _KpiCard(item: e.value)
              .animate(delay: (e.key * 40).ms)
              .fadeIn()
              .slideY(begin: 0.04))
          .toList(),
    );
  }
}

class _KpiItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String sub;

  const _KpiItem(this.title, this.value, this.icon, this.color, this.sub);
}

// ─────────────────────────────────────────────────────────────────────────────
// _KpiCard — FIXED (no layout overflow)
// ─────────────────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final _KpiItem item;

  const _KpiCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _cardDecor(borderColor: item.color.withOpacity(0.15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Top row: icon + dot
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(item.icon, color: item.color, size: 17),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(color: item.color, shape: BoxShape.circle),
              ),
            ],
          ),
          const Spacer(),
          // Value — shrinks automatically if the number is wide
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              item.value,
              style: TextStyle(
                color: item.color,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _DT.micro.copyWith(color: _DT.c600),
          ),
          Text(
            item.sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _DT.micro.copyWith(color: item.color.withOpacity(0.75)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHART CARDS
// ─────────────────────────────────────────────────────────────────────────────

class _PieCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_LegendDatum> data;
  final String Function(String) labels;
  final List<Color> colors;

  const _PieCard({
    required this.title,
    required this.icon,
    required this.data,
    required this.labels,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.fold<int>(0, (sum, item) => sum + item.value);
    final clean = data.where((e) => e.value > 0).toList();

    return _CardShell(
      title: title,
      icon: icon,
      child: total == 0 || clean.isEmpty
          ? const _NoData()
          : Column(
              children: [
                SizedBox(
                  height: 190,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 44,
                      sectionsSpace: 3,
                      sections: List.generate(clean.length, (i) {
                        final color = colors[i % colors.length];
                        final pct = clean[i].value / total * 100;
                        return PieChartSectionData(
                          value: clean[i].value.toDouble(),
                          color: color,
                          radius: 42,
                          title: pct < 5 ? '' : '${pct.toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: List.generate(
                    clean.length,
                    (i) => _LegendDot(
                      color: colors[i % colors.length],
                      label: '${labels(clean[i].label)} (${clean[i].value})',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _BarChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_BarDatum> data;
  final Color color;

  const _BarChartCard({
    required this.title,
    required this.icon,
    required this.data,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clean = data.where((e) => e.value > 0).take(8).toList();
    final maxValue =
        clean.isEmpty ? 1.0 : clean.map((e) => e.value).reduce(math.max);

    return _CardShell(
      title: title,
      icon: icon,
      child: clean.isEmpty
          ? const _NoData()
          : SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  maxY: maxValue + 2,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: _DT.c200, strokeWidth: 1),
                  ),
                  titlesData: _barTitles(clean),
                  barGroups: List.generate(clean.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: clean[i].value,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8)),
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.45)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
    );
  }
}

class _StackedBarCard extends StatelessWidget {
  final List<_StackDatum> data;
  final bool isAr;

  const _StackedBarCard({required this.data, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final clean = data.where((e) => e.total > 0).take(8).toList();
    final maxValue =
        clean.isEmpty ? 1.0 : clean.map((e) => e.total).reduce(math.max);

    return _CardShell(
      title: isAr ? 'تنفيذ المهام لكل فني' : 'Task Execution by Technician',
      icon: Icons.stacked_bar_chart_rounded,
      child: clean.isEmpty
          ? const _NoData()
          : Column(
              children: [
                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      maxY: maxValue + 2,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) =>
                            const FlLine(color: _DT.c200, strokeWidth: 1),
                      ),
                      titlesData: _stackTitles(clean),
                      barGroups: List.generate(clean.length, (i) {
                        final item = clean[i];
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: item.total,
                              width: 22,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8)),
                              rodStackItems: [
                                if (item.pending > 0)
                                  BarChartRodStackItem(
                                      0, item.pending, _DT.amber),
                                if (item.inProgress > 0)
                                  BarChartRodStackItem(
                                      item.pending,
                                      item.pending + item.inProgress,
                                      _DT.cyan),
                                if (item.completed > 0)
                                  BarChartRodStackItem(
                                      item.pending + item.inProgress,
                                      item.total,
                                      _DT.green),
                              ],
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _LegendDot(
                        color: _DT.green,
                        label: isAr ? 'مكتملة' : 'Completed'),
                    _LegendDot(
                        color: _DT.cyan,
                        label: isAr ? 'جارية' : 'In Progress'),
                    _LegendDot(
                        color: _DT.amber,
                        label: isAr ? 'معلقة' : 'Pending'),
                  ],
                ),
              ],
            ),
    );
  }
}

class _SimpleLineChart extends StatelessWidget {
  final List<_LineDatum> data;
  final Color color;
  final double height;

  const _SimpleLineChart({
    required this.data,
    required this.color,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const _NoData();
    final maxValue = data.map((e) => e.value).reduce(math.max);

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxValue + 2,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: _DT.c200, strokeWidth: 1),
          ),
          titlesData: _lineTitles(data),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                  data.length, (i) => FlSpot(i.toDouble(), data[i].value)),
              isCurved: true,
              barWidth: 3,
              color: color,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4,
                  color: color,
                  strokeColor: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.16), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _AnalysisHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String mainValue;
  final String mainLabel;
  final IconData icon;
  final Color color;

  const _AnalysisHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.mainValue,
    required this.mainLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.20)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontFamily: 'Cairo',
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                mainValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                ),
              ),
              Text(
                mainLabel,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}

class _SmallStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SmallStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecor(borderColor: color.withOpacity(0.15)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _DT.micro.copyWith(color: _DT.c600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthBar extends StatelessWidget {
  final String label;
  final double value;
  final int count;
  final Color color;

  const _HealthBar({
    required this.label,
    required this.value,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: _DT.captionBold.copyWith(color: _DT.c900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Text(
              '$count  ${(value * 100).round()}%',
              style: _DT.captionBold.copyWith(color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: _DT.c200,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _CardShell extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _CardShell({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _DT.blueLight,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: _DT.blue, size: 15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: _DT.bodyBold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ).animate().fadeIn(duration: 240.ms).slideY(begin: 0.03);
  }
}

class _TwoCol extends StatelessWidget {
  final Widget first;
  final Widget second;

  const _TwoCol({required this.first, required this.second});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
              children: [first, const SizedBox(height: 12), second]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: _DT.h3);
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: _DT.micro.copyWith(color: color, fontWeight: FontWeight.w900),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: _DT.micro,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final _ActivityItem item;
  final bool isAr;

  const _ActivityRow({required this.item, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: _DT.bodyBold.copyWith(fontSize: 12.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.subtitle,
                  style: _DT.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _timeAgo(item.date, isAr),
                      style: _DT.micro,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.type,
                        style: _DT.micro.copyWith(
                            color: item.color, fontWeight: FontWeight.w900),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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

class _NoData extends StatelessWidget {
  const _NoData();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 28, color: _DT.c400),
            const SizedBox(height: 8),
            Text(
              'لا توجد بيانات',
              style: _DT.captionBold,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: List.generate(
          6,
          (i) => Container(
            height: i == 0 ? 160 : 110,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
              duration: 900.ms, color: _DT.c100),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _DT.redLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: _DT.red, size: 44),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: _DT.caption.copyWith(color: _DT.red),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _DT.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

BoxDecoration _cardDecor({Color borderColor = _DT.c200}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: borderColor),
    boxShadow: _DT.shadowCard,
  );
}

FlTitlesData _barTitles(List<_BarDatum> clean) {
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        reservedSize: 28,
        showTitles: true,
        getTitlesWidget: (value, _) =>
            Text(value.toInt().toString(), style: _DT.micro),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        reservedSize: 44,
        showTitles: true,
        getTitlesWidget: (value, _) {
          final i = value.toInt();
          if (i < 0 || i >= clean.length) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: SizedBox(
              width: 52,
              child: Text(
                clean[i].label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: _DT.micro,
              ),
            ),
          );
        },
      ),
    ),
  );
}

FlTitlesData _lineTitles(List<_LineDatum> clean) {
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        reservedSize: 28,
        showTitles: true,
        getTitlesWidget: (value, _) =>
            Text(value.toInt().toString(), style: _DT.micro),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        reservedSize: 30,
        showTitles: true,
        getTitlesWidget: (value, _) {
          final i = value.toInt();
          if (i < 0 || i >= clean.length) return const SizedBox.shrink();
          if (i % 2 != 0) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(clean[i].label, style: _DT.micro),
          );
        },
      ),
    ),
  );
}

FlTitlesData _stackTitles(List<_StackDatum> clean) {
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        reservedSize: 28,
        showTitles: true,
        getTitlesWidget: (value, _) =>
            Text(value.toInt().toString(), style: _DT.micro),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        reservedSize: 42,
        showTitles: true,
        getTitlesWidget: (value, _) {
          final i = value.toInt();
          if (i < 0 || i >= clean.length) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: SizedBox(
              width: 55,
              child: Text(
                clean[i].label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: _DT.micro,
              ),
            ),
          );
        },
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// LOGIC HELPERS
// ─────────────────────────────────────────────────────────────────────────────

String _norm(String value) => value.trim().toUpperCase();

String _safeLabel(String? value, {required String fallback}) {
  if (value == null || value.trim().isEmpty) return fallback;
  return value.trim();
}

bool _isOkDevice(String status) {
  final n = _norm(status);
  return n == 'OK' || n == 'GOOD' || n == 'HEALTHY' || n == 'WORKING';
}

bool _isMaintenanceDevice(String status) {
  final n = _norm(status);
  return n == 'MAINTENANCE' ||
      n == 'NEEDS_MAINTENANCE' ||
      n == 'UNDER_MAINTENANCE' ||
      n == 'PARTIAL';
}

bool _isFaultDevice(String status) {
  final n = _norm(status);
  return n == 'OUT_OF_SERVICE' ||
      n == 'NOT_OK' ||
      n == 'NOT_REACHABLE' ||
      n == 'FAULTY' ||
      n == 'DOWN';
}

List<_BarDatum> _barList(Map<String, int> map) {
  return map.entries
      .map((e) => _BarDatum(e.key, e.value.toDouble()))
      .toList()
    ..sort((a, b) => b.value.compareTo(a.value));
}

List<_LineDatum> _lastDaysTrendFromTasks(List<TaskModel> tasks, int days) {
  final now = DateTime.now();
  return List.generate(days, (i) {
    final day = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1 - i));
    final count = tasks.where((task) {
      final date = task.completedAt ?? task.createdAt;
      return date.year == day.year &&
          date.month == day.month &&
          date.day == day.day &&
          _norm(task.status) == 'COMPLETED';
    }).length;
    return _LineDatum('${day.day}/${day.month}', count.toDouble());
  });
}

List<_LineDatum> _lastDaysTrendFromInspections(
    List<InspectionDetail> inspections, int days) {
  final now = DateTime.now();
  return List.generate(days, (i) {
    final day = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1 - i));
    final count = inspections.where((inspection) {
      final date = inspection.inspectedAt;
      return date.year == day.year &&
          date.month == day.month &&
          date.day == day.day;
    }).length;
    return _LineDatum('${day.day}/${day.month}', count.toDouble());
  });
}

List<_ActivityItem> _buildActivity(
  List<TaskModel> tasks,
  List<InspectionDetail> inspections,
) {
  final items = <_ActivityItem>[];

  for (final task in tasks) {
    final status = _norm(task.status);
    final color = status == 'COMPLETED'
        ? _DT.green
        : status == 'IN_PROGRESS'
            ? _DT.cyan
            : status == 'OVERDUE'
                ? _DT.red
                : _DT.amber;

    items.add(_ActivityItem(
      title: task.title,
      subtitle:
          '${task.assignedToName ?? 'Unassigned'} • ${task.deviceName ?? task.deviceCode ?? ''}',
      date: task.completedAt ?? task.createdAt,
      icon: status == 'COMPLETED'
          ? Icons.check_circle_rounded
          : Icons.assignment_rounded,
      color: color,
      type: status,
    ));
  }

  for (final inspection in inspections) {
    final status = _norm(inspection.inspectionStatus);
    final color = status == 'OK'
        ? _DT.green
        : status == 'NOT_OK'
            ? _DT.red
            : status == 'PARTIAL'
                ? _DT.amber
                : _DT.c400;

    items.add(_ActivityItem(
      title: inspection.deviceName,
      subtitle: '${inspection.technicianName} • ${inspection.reportNumber}',
      date: inspection.inspectedAt,
      icon: Icons.fact_check_rounded,
      color: color,
      type: status,
    ));
  }

  items.sort((a, b) => b.date.compareTo(a.date));
  return items.take(20).toList();
}

String _deviceLabel(String value, bool isAr) {
  if (!isAr) return value.replaceAll('_', ' ');
  return switch (value.toUpperCase()) {
    'OK' => 'سليم',
    'MAINTENANCE' || 'NEEDS_MAINTENANCE' || 'UNDER_MAINTENANCE' => 'صيانة',
    'OUT_OF_SERVICE' => 'خارج الخدمة',
    'OTHER' => 'أخرى',
    _ => value,
  };
}

String _taskLabel(String value, bool isAr) {
  if (!isAr) return value.replaceAll('_', ' ');
  return switch (value.toUpperCase()) {
    'PENDING' => 'معلقة',
    'IN_PROGRESS' => 'جارية',
    'COMPLETED' => 'مكتملة',
    'OVERDUE' => 'متأخرة',
    'URGENT' => 'طارئة',
    'CANCELLED' => 'ملغاة',
    _ => value,
  };
}

String _inspectionLabel(String value, bool isAr) {
  if (!isAr) return value.replaceAll('_', ' ');
  return switch (value.toUpperCase()) {
    'OK' => 'سليم',
    'NOT_OK' => 'غير سليم',
    'PARTIAL' => 'جزئي',
    'NOT_REACHABLE' => 'غير متاح',
    _ => value,
  };
}

String _timeAgo(DateTime date, bool isAr) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return isAr ? 'الآن' : 'Now';
  if (diff.inMinutes < 60) {
    return isAr ? 'منذ ${diff.inMinutes} د' : '${diff.inMinutes}m';
  }
  if (diff.inHours < 24) {
    return isAr ? 'منذ ${diff.inHours} س' : '${diff.inHours}h';
  }
  return isAr ? 'منذ ${diff.inDays} ي' : '${diff.inDays}d';
}