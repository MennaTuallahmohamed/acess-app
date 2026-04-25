import 'dart:math' as math;

import 'package:access_track/admin/admin_models.dart';
import 'package:access_track/admin/admin_providers.dart';
import 'package:access_track/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = AppLocalizations.of(context).isAr;
    final analyticsAsync = ref.watch(adminAnalyticsProvider);

    void refresh() {
      ref.invalidate(adminStatsProvider);
      ref.invalidate(allTasksProvider);
      ref.invalidate(activeTechniciansProvider);
      ref.invalidate(techniciansProvider);
      ref.invalidate(adminDevicesProvider(null));
      ref.invalidate(monthlyInspectionsProvider);
      ref.invalidate(adminAnalyticsProvider);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        bottom: false,
        child: analyticsAsync.when(
          loading: () => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  isAr: isAr,
                  onBack: () => _goBack(context, ref),
                  onRefresh: refresh,
                ),
              ),
              const SliverToBoxAdapter(child: _LoadingView()),
            ],
          ),
          error: (e, _) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  isAr: isAr,
                  onBack: () => _goBack(context, ref),
                  onRefresh: refresh,
                ),
              ),
              SliverToBoxAdapter(
                child: _ErrorView(message: e.toString(), onRetry: refresh),
              ),
            ],
          ),
          data: (analytics) {
            return DefaultTabController(
              length: 4,
              child: NestedScrollView(
                headerSliverBuilder: (context, _) => [
                  SliverToBoxAdapter(
                    child: _Header(
                      isAr: isAr,
                      onBack: () => _goBack(context, ref),
                      onRefresh: refresh,
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabHeaderDelegate(
                      child: _AnalyticsTabs(isAr: isAr),
                    ),
                  ),
                ],
                body: TabBarView(
                  children: [
                    _OverviewTab(analytics: analytics, isAr: isAr),
                    _DevicesTab(analytics: analytics, isAr: isAr),
                    _TechniciansTab(analytics: analytics, isAr: isAr),
                    _TrendsTab(analytics: analytics, isAr: isAr),
                  ],
                ),
              ),
            );
          },
        ),
      ),
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

class _Header extends StatelessWidget {
  final bool isAr;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _Header({
    required this.isAr,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E3A8A),
            Color(0xFF7C3AED),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          _IconButtonLite(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          const SizedBox(width: 10),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.13),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(.12)),
            ),
            child: const Icon(Icons.analytics_rounded, color: Colors.white),
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
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  isAr
                      ? 'تحليل الأجهزة والفنيين والمهام من الباك إند'
                      : 'Devices, technicians and tasks from backend',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.68),
                    fontFamily: 'Cairo',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _IconButtonLite(icon: Icons.refresh_rounded, onTap: onRefresh),
        ],
      ),
    );
  }
}

class _AnalyticsTabs extends StatelessWidget {
  final bool isAr;

  const _AnalyticsTabs({required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FB),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: TabBar(
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: const Color(0xFF1A237E),
            borderRadius: BorderRadius.circular(12),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
          tabs: [
            Tab(text: isAr ? 'عام' : 'Overview'),
            Tab(text: isAr ? 'الأجهزة' : 'Devices'),
            Tab(text: isAr ? 'الفنيين' : 'Techs'),
            Tab(text: isAr ? 'الاتجاهات' : 'Trends'),
          ],
        ),
      ),
    );
  }
}

class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  const _TabHeaderDelegate({required this.child});

  @override
  double get minExtent => 62;

  @override
  double get maxExtent => 62;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _TabHeaderDelegate oldDelegate) => false;
}

class _OverviewTab extends StatelessWidget {
  final AdminAnalyticsData analytics;
  final bool isAr;

  const _OverviewTab({required this.analytics, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 110),
      children: [
        _Hero(stats: analytics.stats, isAr: isAr),
        const SizedBox(height: 12),
        _KpiGrid(stats: analytics.stats, isAr: isAr),
        const SizedBox(height: 18),
        _Section(title: isAr ? 'توزيع الحالات' : 'Status Distribution'),
        const SizedBox(height: 10),
        _TwoColumnResponsive(
          first: _PieCard(
            title: isAr ? 'حالة الأجهزة' : 'Device Status',
            icon: Icons.devices_rounded,
            data: analytics.deviceStatus,
            labels: (v) => _deviceLabel(v, isAr),
            colors: const [
              Color(0xFF16A34A),
              Color(0xFFF59E0B),
              Color(0xFFDC2626),
              Color(0xFF64748B),
            ],
          ),
          second: _PieCard(
            title: isAr ? 'حالة المهام' : 'Task Status',
            icon: Icons.task_alt_rounded,
            data: analytics.taskStatus,
            labels: (v) => _taskLabel(v, isAr),
            colors: const [
              Color(0xFFF59E0B),
              Color(0xFF0284C7),
              Color(0xFF16A34A),
              Color(0xFFDC2626),
              Color(0xFF64748B),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _Section(title: isAr ? 'أهم المؤشرات' : 'Key Indicators'),
        const SizedBox(height: 10),
        _InsightCards(stats: analytics.stats, isAr: isAr),
      ],
    );
  }
}

class _DevicesTab extends StatelessWidget {
  final AdminAnalyticsData analytics;
  final bool isAr;

  const _DevicesTab({required this.analytics, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final stats = analytics.stats;
    final totalDevices = stats.totalDevices == 0 ? 1 : stats.totalDevices;
    final okRate = stats.okDevices / totalDevices;
    final maintenanceRate = stats.maintenanceDevices / totalDevices;
    final outRate = stats.outOfServiceDevices / totalDevices;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 110),
      children: [
        _AnalysisHeaderCard(
          title: isAr ? 'تحليل الأجهزة' : 'Device Analysis',
          subtitle: isAr
              ? 'سلامة الأجهزة وتوزيعها حسب المبنى والنوع'
              : 'Device health, building distribution and type analysis',
          icon: Icons.devices_other_rounded,
          color: const Color(0xFF1A237E),
          mainValue: '${(okRate * 100).round()}%',
          mainLabel: isAr ? 'أجهزة سليمة' : 'Healthy devices',
        ),
        const SizedBox(height: 12),
        _HealthMeters(
          items: [
            _MeterData(
              label: isAr ? 'سليم' : 'Healthy',
              value: okRate,
              count: stats.okDevices,
              color: const Color(0xFF16A34A),
            ),
            _MeterData(
              label: isAr ? 'يحتاج صيانة' : 'Maintenance',
              value: maintenanceRate,
              count: stats.maintenanceDevices,
              color: const Color(0xFFF59E0B),
            ),
            _MeterData(
              label: isAr ? 'خارج الخدمة' : 'Out of service',
              value: outRate,
              count: stats.outOfServiceDevices,
              color: const Color(0xFFDC2626),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _PieCard(
          title: isAr ? 'نسب حالات الأجهزة' : 'Device Status Percentages',
          icon: Icons.donut_large_rounded,
          data: analytics.deviceStatus,
          labels: (v) => _deviceLabel(v, isAr),
          colors: const [
            Color(0xFF16A34A),
            Color(0xFFF59E0B),
            Color(0xFFDC2626),
            Color(0xFF64748B),
          ],
        ),
        const SizedBox(height: 12),
        _BarChartCard(
          title: isAr ? 'الأجهزة حسب المبنى' : 'Devices by Building',
          icon: Icons.apartment_rounded,
          data: analytics.devicesByBuilding,
          color: const Color(0xFF1A237E),
        ),
        const SizedBox(height: 12),
        _BarChartCard(
          title: isAr ? 'الأجهزة حسب النوع' : 'Devices by Type',
          icon: Icons.category_rounded,
          data: analytics.devicesByType,
          color: const Color(0xFF7C3AED),
        ),
        const SizedBox(height: 12),
        _DeviceSummaryTable(
          data: analytics.devicesByType,
          isAr: isAr,
        ),
      ],
    );
  }
}

class _TechniciansTab extends StatelessWidget {
  final AdminAnalyticsData analytics;
  final bool isAr;

  const _TechniciansTab({required this.analytics, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final stats = analytics.stats;
    final activeRate = stats.totalTechnicians == 0
        ? 0.0
        : stats.activeTechnicians / stats.totalTechnicians;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 110),
      children: [
        _AnalysisHeaderCard(
          title: isAr ? 'تحليل الفنيين' : 'Technician Analysis',
          subtitle: isAr
              ? 'أداء الفنيين، تنفيذ المهام، وعدد التفتيشات'
              : 'Technician performance, task execution and inspections',
          icon: Icons.engineering_rounded,
          color: const Color(0xFF0F766E),
          mainValue: '${(activeRate * 100).round()}%',
          mainLabel: isAr ? 'فنيين نشطين' : 'Active technicians',
        ),
        const SizedBox(height: 12),
        _TechnicianKpis(stats: stats, isAr: isAr),
        const SizedBox(height: 12),
        _BarChartCard(
          title: isAr ? 'أداء الفنيين' : 'Technician Performance',
          icon: Icons.leaderboard_rounded,
          data: analytics.technicianPerformance,
          color: const Color(0xFF0F766E),
        ),
        const SizedBox(height: 12),
        _StackedBarCard(
          data: analytics.taskExecutionByTechnician,
          isAr: isAr,
        ),
        const SizedBox(height: 12),
        _TechnicianExecutionList(
          data: analytics.taskExecutionByTechnician,
          isAr: isAr,
        ),
      ],
    );
  }
}

class _TrendsTab extends StatelessWidget {
  final AdminAnalyticsData analytics;
  final bool isAr;

  const _TrendsTab({required this.analytics, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 110),
      children: [
        _AnalysisHeaderCard(
          title: isAr ? 'الاتجاهات الزمنية' : 'Time Trends',
          subtitle: isAr
              ? 'تغير إنجاز المهام والتفتيشات خلال الفترة الأخيرة'
              : 'Task completion and inspection movement over time',
          icon: Icons.timeline_rounded,
          color: const Color(0xFF0284C7),
          mainValue: '${analytics.stats.totalInspectionsMonth}',
          mainLabel: isAr ? 'فحوصات الشهر' : 'Month checks',
        ),
        const SizedBox(height: 12),
        _LineChartCard(
          title: isAr ? 'اتجاه إنجاز المهام' : 'Task Completion Trend',
          icon: Icons.show_chart_rounded,
          data: analytics.taskCompletionTrend,
          color: const Color(0xFF16A34A),
        ),
        const SizedBox(height: 12),
        _LineChartCard(
          title: isAr ? 'التفتيشات عبر الزمن' : 'Inspections Over Time',
          icon: Icons.timeline_rounded,
          data: analytics.inspectionsOverTime,
          color: const Color(0xFF0284C7),
        ),
        const SizedBox(height: 12),
        _TrendComparisonCard(
          tasks: analytics.taskCompletionTrend,
          inspections: analytics.inspectionsOverTime,
          isAr: isAr,
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  final AdminStats stats;
  final bool isAr;

  const _Hero({required this.stats, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final taskRate = stats.totalTasks == 0
        ? 0
        : (stats.completedTasks / stats.totalTasks * 100).round();
    final deviceRate = stats.totalDevices == 0
        ? 0
        : (stats.okDevices / stats.totalDevices * 100).round();
    final avg = ((taskRate + deviceRate) / 2).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          SizedBox(
            width: 118,
            height: 118,
            child: CustomPaint(
              painter: _RingPainter(
                value: avg / 100,
                color: const Color(0xFF1A237E),
              ),
              child: Center(
                child: Text(
                  '$avg%',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 23,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'معدل الأداء العام' : 'Overall Performance',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  isAr
                      ? 'محسوب من إنجاز المهام وسلامة الأجهزة.'
                      : 'Based on task completion and device health.',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _Pill(
                      text:
                          '${stats.completedTasks}/${stats.totalTasks} ${isAr ? 'مهام' : 'tasks'}',
                      color: const Color(0xFF16A34A),
                    ),
                    _Pill(
                      text:
                          '${stats.okDevices}/${stats.totalDevices} ${isAr ? 'أجهزة' : 'devices'}',
                      color: const Color(0xFF1A237E),
                    ),
                    _Pill(
                      text:
                          '${stats.totalInspectionsMonth} ${isAr ? 'فحص' : 'checks'}',
                      color: const Color(0xFF7C3AED),
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

class _KpiGrid extends StatelessWidget {
  final AdminStats stats;
  final bool isAr;

  const _KpiGrid({required this.stats, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiData(
        title: isAr ? 'كل المهام' : 'Tasks',
        value: stats.totalTasks.toString(),
        icon: Icons.assignment_rounded,
        color: const Color(0xFF1A237E),
      ),
      _KpiData(
        title: isAr ? 'مكتملة' : 'Completed',
        value: stats.completedTasks.toString(),
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF16A34A),
      ),
      _KpiData(
        title: isAr ? 'الأجهزة' : 'Devices',
        value: stats.totalDevices.toString(),
        icon: Icons.devices_rounded,
        color: const Color(0xFF7C3AED),
      ),
      _KpiData(
        title: isAr ? 'الفنيين' : 'Techs',
        value: stats.activeTechnicians.toString(),
        icon: Icons.engineering_rounded,
        color: const Color(0xFF0F766E),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth < 700
            ? (constraints.maxWidth - 10) / 2
            : (constraints.maxWidth - 30) / 4;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((item) {
            return SizedBox(width: itemWidth, child: _KpiCard(data: item));
          }).toList(),
        );
      },
    );
  }
}

class _KpiData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;

  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(borderColor: data.color.withOpacity(.14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: data.color, size: 24),
          const SizedBox(height: 10),
          Text(
            data.value,
            style: TextStyle(
              color: data.color,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String mainValue;
  final String mainLabel;

  const _AnalysisHeaderCard({
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
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [color, color.withOpacity(.74)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(.16)),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 13),
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
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.72),
                    fontFamily: 'Cairo',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                mainValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                  fontSize: 25,
                ),
              ),
              Text(
                mainLabel,
                style: TextStyle(
                  color: Colors.white.withOpacity(.72),
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeterData {
  final String label;
  final double value;
  final int count;
  final Color color;

  const _MeterData({
    required this.label,
    required this.value,
    required this.count,
    required this.color,
  });
}

class _HealthMeters extends StatelessWidget {
  final List<_MeterData> items;

  const _HealthMeters({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Text(
                      '${item.count}  ${(item.value * 100).round()}%',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        color: item.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: item.value.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation(item.color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TechnicianKpis extends StatelessWidget {
  final AdminStats stats;
  final bool isAr;

  const _TechnicianKpis({required this.stats, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final avgTasks = stats.activeTechnicians == 0
        ? 0.0
        : stats.totalTasks / stats.activeTechnicians;
    final avgChecks = stats.activeTechnicians == 0
        ? 0.0
        : stats.totalInspectionsMonth / stats.activeTechnicians;

    return _TwoColumnResponsive(
      first: _MiniAnalysisCard(
        title: isAr ? 'متوسط المهام لكل فني' : 'Avg tasks per tech',
        value: avgTasks.toStringAsFixed(1),
        icon: Icons.assignment_ind_rounded,
        color: const Color(0xFF1A237E),
      ),
      second: _MiniAnalysisCard(
        title: isAr ? 'متوسط الفحوصات لكل فني' : 'Avg checks per tech',
        value: avgChecks.toStringAsFixed(1),
        icon: Icons.fact_check_rounded,
        color: const Color(0xFF0F766E),
      ),
    );
  }
}

class _MiniAnalysisCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniAnalysisCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(borderColor: color.withOpacity(.14)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: color,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
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

class _TwoColumnResponsive extends StatelessWidget {
  final Widget first;
  final Widget second;

  const _TwoColumnResponsive({required this.first, required this.second});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: [
              first,
              const SizedBox(height: 12),
              second,
            ],
          );
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

class _PieCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<AnalyticsLegendItem> data;
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
    final total = data.fold<int>(0, (sum, e) => sum + e.value);
    final clean = data.where((e) => e.value > 0).toList();

    return _CardShell(
      title: title,
      icon: icon,
      child: total == 0 || clean.isEmpty
          ? const _NoData()
          : Column(
              children: [
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 52,
                      sectionsSpace: 4,
                      sections: List.generate(clean.length, (i) {
                        final item = clean[i];
                        final color = colors[i % colors.length];
                        final percent = item.value / total * 100;

                        return PieChartSectionData(
                          value: item.value.toDouble(),
                          color: color,
                          radius: 46,
                          title: '${percent.toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: List.generate(clean.length, (i) {
                    final item = clean[i];
                    return _LegendDot(
                      color: colors[i % colors.length],
                      label: '${labels(item.label)} (${item.value})',
                    );
                  }),
                ),
              ],
            ),
    );
  }
}

class _BarChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<AnalyticsBarDatum> data;
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
    final maxValue = clean.isEmpty
        ? 1.0
        : clean.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return _CardShell(
      title: title,
      icon: icon,
      child: clean.isEmpty
          ? const _NoData()
          : SizedBox(
              height: 260,
              child: BarChart(
                BarChartData(
                  maxY: maxValue + 2,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: const Color(0xFFE2E8F0),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        reservedSize: 28,
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 9,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        reservedSize: 48,
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= clean.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: SizedBox(
                              width: 55,
                              child: Text(
                                clean[i].label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 9,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(clean.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: clean[i].value,
                          width: 18,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(.45)],
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

class _LineChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<AnalyticsLineDatum> data;
  final Color color;

  const _LineChartCard({
    required this.title,
    required this.icon,
    required this.data,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clean = data.take(14).toList();
    final maxValue = clean.isEmpty
        ? 1.0
        : clean.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return _CardShell(
      title: title,
      icon: icon,
      child: clean.isEmpty
          ? const _NoData()
          : SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxValue + 2,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: const Color(0xFFE2E8F0),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        reservedSize: 28,
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 9,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        reservedSize: 34,
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= clean.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              clean[i].label,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 9,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(clean.length, (i) {
                        return FlSpot(i.toDouble(), clean[i].value);
                      }),
                      isCurved: true,
                      barWidth: 4,
                      color: color,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [color.withOpacity(.18), Colors.transparent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StackedBarCard extends StatelessWidget {
  final List<AnalyticsStackedDatum> data;
  final bool isAr;

  const _StackedBarCard({required this.data, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final clean = data
        .where((e) => e.completed + e.inProgress + e.pending > 0)
        .take(8)
        .toList();
    final maxValue = clean.isEmpty
        ? 1.0
        : clean
            .map((e) => e.completed + e.inProgress + e.pending)
            .reduce((a, b) => a > b ? a : b);

    return _CardShell(
      title: isAr ? 'تنفيذ المهام لكل فني' : 'Task Execution by Technician',
      icon: Icons.stacked_bar_chart_rounded,
      child: clean.isEmpty
          ? const _NoData()
          : Column(
              children: [
                SizedBox(
                  height: 270,
                  child: BarChart(
                    BarChartData(
                      maxY: maxValue + 2,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: const Color(0xFFE2E8F0),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            reservedSize: 28,
                            showTitles: true,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 9,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            reservedSize: 45,
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= clean.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: SizedBox(
                                  width: 58,
                                  child: Text(
                                    clean[i].label,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 9,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(clean.length, (i) {
                        final item = clean[i];
                        final pendingEnd = item.pending;
                        final progressEnd = item.pending + item.inProgress;
                        final completedEnd =
                            item.pending + item.inProgress + item.completed;

                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: completedEnd,
                              width: 20,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                              rodStackItems: [
                                if (item.pending > 0)
                                  BarChartRodStackItem(
                                    0,
                                    pendingEnd,
                                    const Color(0xFFF59E0B),
                                  ),
                                if (item.inProgress > 0)
                                  BarChartRodStackItem(
                                    pendingEnd,
                                    progressEnd,
                                    const Color(0xFF0284C7),
                                  ),
                                if (item.completed > 0)
                                  BarChartRodStackItem(
                                    progressEnd,
                                    completedEnd,
                                    const Color(0xFF16A34A),
                                  ),
                              ],
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _LegendDot(
                      color: const Color(0xFF16A34A),
                      label: isAr ? 'مكتملة' : 'Completed',
                    ),
                    _LegendDot(
                      color: const Color(0xFF0284C7),
                      label: isAr ? 'جارية' : 'In progress',
                    ),
                    _LegendDot(
                      color: const Color(0xFFF59E0B),
                      label: isAr ? 'معلقة' : 'Pending',
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _TechnicianExecutionList extends StatelessWidget {
  final List<AnalyticsStackedDatum> data;
  final bool isAr;

  const _TechnicianExecutionList({required this.data, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final clean = data
        .where((e) => e.completed + e.inProgress + e.pending > 0)
        .take(10)
        .toList();

    return _CardShell(
      title: isAr ? 'تفاصيل تنفيذ الفنيين' : 'Technician Execution Details',
      icon: Icons.people_alt_rounded,
      child: clean.isEmpty
          ? const _NoData()
          : Column(
              children: clean.map((item) {
                final total = item.completed + item.inProgress + item.pending;
                final completedRate = total == 0 ? 0.0 : item.completed / total;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          _Pill(
                            text: '${(completedRate * 100).round()}%',
                            color: const Color(0xFF16A34A),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: completedRate.clamp(0.0, 1.0),
                          minHeight: 9,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF16A34A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _Pill(
                            text:
                                '${item.completed.toInt()} ${isAr ? 'مكتملة' : 'done'}',
                            color: const Color(0xFF16A34A),
                          ),
                          _Pill(
                            text:
                                '${item.inProgress.toInt()} ${isAr ? 'جارية' : 'running'}',
                            color: const Color(0xFF0284C7),
                          ),
                          _Pill(
                            text:
                                '${item.pending.toInt()} ${isAr ? 'معلقة' : 'pending'}',
                            color: const Color(0xFFF59E0B),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _DeviceSummaryTable extends StatelessWidget {
  final List<AnalyticsBarDatum> data;
  final bool isAr;

  const _DeviceSummaryTable({required this.data, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final clean = data.where((e) => e.value > 0).take(10).toList();

    return _CardShell(
      title: isAr ? 'ملخص أنواع الأجهزة' : 'Device Type Summary',
      icon: Icons.table_chart_rounded,
      child: clean.isEmpty
          ? const _NoData()
          : Column(
              children: clean.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.value.toInt().toString(),
                          style: const TextStyle(
                            color: Color(0xFF7C3AED),
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _TrendComparisonCard extends StatelessWidget {
  final List<AnalyticsLineDatum> tasks;
  final List<AnalyticsLineDatum> inspections;
  final bool isAr;

  const _TrendComparisonCard({
    required this.tasks,
    required this.inspections,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    final totalTasks = tasks.fold<double>(0, (sum, e) => sum + e.value).toInt();
    final totalInspections =
        inspections.fold<double>(0, (sum, e) => sum + e.value).toInt();

    return _CardShell(
      title: isAr ? 'مقارنة الحركة' : 'Movement Comparison',
      icon: Icons.compare_arrows_rounded,
      child: Row(
        children: [
          Expanded(
            child: _MiniAnalysisCard(
              title: isAr ? 'إنجاز مهام' : 'Task completions',
              value: '$totalTasks',
              icon: Icons.task_alt_rounded,
              color: const Color(0xFF16A34A),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniAnalysisCard(
              title: isAr ? 'تفتيشات' : 'Inspections',
              value: '$totalInspections',
              icon: Icons.fact_check_rounded,
              color: const Color(0xFF0284C7),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCards extends StatelessWidget {
  final AdminStats stats;
  final bool isAr;

  const _InsightCards({required this.stats, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final totalTasks = stats.totalTasks == 0 ? 1 : stats.totalTasks;
    final totalDevices = stats.totalDevices == 0 ? 1 : stats.totalDevices;
    final completionRate = stats.completedTasks / totalTasks;
    final faultRate = stats.outOfServiceDevices / totalDevices;

    return Column(
      children: [
        _InsightTile(
          title: isAr ? 'نسبة إنجاز المهام' : 'Task completion rate',
          value: '${(completionRate * 100).round()}%',
          icon: Icons.task_alt_rounded,
          color: const Color(0xFF16A34A),
        ),
        const SizedBox(height: 10),
        _InsightTile(
          title: isAr ? 'نسبة الأعطال' : 'Fault rate',
          value: '${(faultRate * 100).round()}%',
          icon: Icons.warning_rounded,
          color: const Color(0xFFDC2626),
        ),
      ],
    );
  }
}

class _InsightTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InsightTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(borderColor: color.withOpacity(.14)),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1A237E)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ).animate().fadeIn(duration: 240.ms).slideY(begin: .03);
  }
}

class _Section extends StatelessWidget {
  final String title;

  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.w900,
        fontSize: 16,
        color: Color(0xFF0F172A),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontFamily: 'Cairo',
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _NoData extends StatelessWidget {
  const _NoData();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(18),
      child: Center(
        child: Text(
          'No data',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _IconButtonLite extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButtonLite({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(.12)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
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
          7,
          (i) => Container(
            height: i == 0 ? 150 : 120,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
                duration: 900.ms,
              ),
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFDC2626),
              size: 42,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
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
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      value.clamp(0.0, 1.0) * 2 * math.pi,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) {
    return old.value != value || old.color != color;
  }
}

BoxDecoration _cardDecoration({Color borderColor = const Color(0xFFE2E8F0)}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: borderColor),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0F172A).withOpacity(.035),
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

String _deviceLabel(String value, bool isAr) {
  if (!isAr) return value.replaceAll('_', ' ');

  switch (value.toUpperCase()) {
    case 'OK':
      return 'سليم';
    case 'MAINTENANCE':
    case 'NEEDS_MAINTENANCE':
    case 'UNDER_MAINTENANCE':
      return 'صيانة';
    case 'OUT_OF_SERVICE':
      return 'خارج الخدمة';
    default:
      return value;
  }
}

String _taskLabel(String value, bool isAr) {
  if (!isAr) return value.replaceAll('_', ' ');

  switch (value.toUpperCase()) {
    case 'PENDING':
      return 'معلقة';
    case 'IN_PROGRESS':
      return 'جارية';
    case 'COMPLETED':
      return 'مكتملة';
    case 'OVERDUE':
      return 'متأخرة';
    case 'CANCELLED':
      return 'ملغاة';
    default:
      return value;
  }
}
