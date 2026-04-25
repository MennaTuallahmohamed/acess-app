import 'package:access_track/admin/admin_models.dart';
import 'package:access_track/admin/admin_providers.dart';
import 'package:access_track/app_localizations.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:access_track/core/widgets/widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ════════════════════════════════════════════════════════
//  ADMIN STAT CARD
// ════════════════════════════════════════════════════════

class AdminStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String sub;
  final Color color;
  final Color bg;
  final VoidCallback? onTap;

  const AdminStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.sub,
    required this.color,
    required this.bg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_outward_rounded,
                      color: color.withOpacity(0.65),
                      size: 16,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: AppText.h2.copyWith(
                  color: color,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppText.caption.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (sub.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  sub,
                  style: AppText.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
//  STAT CARD MODEL + GRID
// ════════════════════════════════════════════════════════

class StatCard {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final Color iconBg;

  const StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    required this.iconBg,
  });
}

class ResponsiveStatGrid extends StatelessWidget {
  final List<StatCard> cards;

  const ResponsiveStatGrid({
    super.key,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final itemWidth = isWide
            ? (constraints.maxWidth - 36) / 4
            : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards.map((c) {
            return SizedBox(
              width: itemWidth,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.soft,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: c.iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(c.icon, color: c.iconColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.value,
                            style: AppText.h3.copyWith(
                              color: c.iconColor,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            c.label,
                            style: AppText.caption.copyWith(fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════
//  SECTION HEADER
// ════════════════════════════════════════════════════════

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.iconColor = AppColors.accent,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: AppText.h4.copyWith(fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onAction != null && actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: Text(
              actionLabel!,
              style: AppText.small.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════
//  CHART CARD
// ════════════════════════════════════════════════════════

class AnalyticsChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;

  const AnalyticsChartCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: AppColors.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppText.h4.copyWith(fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (subtitle?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: AppText.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
//  LEGEND
// ════════════════════════════════════════════════════════

class AnalyticsLegend extends StatelessWidget {
  final List<LegendItemData> items;

  const AnalyticsLegend({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              item.showValue ? '${item.label} (${item.value})' : item.label,
              style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class LegendItemData {
  final String label;
  final int value;
  final Color color;
  final bool showValue;

  const LegendItemData({
    required this.label,
    required this.value,
    required this.color,
    this.showValue = true,
  });
}

// ════════════════════════════════════════════════════════
//  DONUT CHARTS
// ════════════════════════════════════════════════════════

class DeviceStatusDonutChart extends StatelessWidget {
  final List<AnalyticsLegendItem> data;

  const DeviceStatusDonutChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final total = data.fold<int>(0, (sum, e) => sum + e.value);

    if (total == 0) {
      return _EmptyChartText(text: l.isAr ? 'لا توجد بيانات أجهزة' : 'No device data');
    }

    final colors = [
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      AppColors.info,
    ];

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 58,
              sections: List.generate(data.length, (i) {
                final item = data[i];
                final percent = item.value <= 0 ? 0 : ((item.value / total) * 100);

                return PieChartSectionData(
                  value: item.value.toDouble(),
                  color: colors[i % colors.length],
                  radius: 44,
                  title: item.value > 0 ? '${percent.toStringAsFixed(0)}%' : '',
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnalyticsLegend(
          items: List.generate(data.length, (i) {
            return LegendItemData(
              label: _deviceStatusLabel(data[i].label, l.isAr),
              value: data[i].value,
              color: colors[i % colors.length],
            );
          }),
        ),
      ],
    );
  }
}

class TaskStatusDonutChart extends StatelessWidget {
  final List<AnalyticsLegendItem> data;

  const TaskStatusDonutChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final total = data.fold<int>(0, (sum, e) => sum + e.value);

    if (total == 0) {
      return _EmptyChartText(text: l.isAr ? 'لا توجد بيانات مهام' : 'No task data');
    }

    final colors = [
      AppColors.warning,
      AppColors.info,
      AppColors.success,
      AppColors.error,
      AppColors.textHint,
    ];

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 54,
              sections: List.generate(data.length, (i) {
                final item = data[i];
                final percent = item.value <= 0 ? 0 : ((item.value / total) * 100);

                return PieChartSectionData(
                  value: item.value.toDouble(),
                  color: colors[i % colors.length],
                  radius: 42,
                  title: item.value > 0 ? '${percent.toStringAsFixed(0)}%' : '',
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnalyticsLegend(
          items: List.generate(data.length, (i) {
            return LegendItemData(
              label: _taskStatusLabel(data[i].label, l.isAr),
              value: data[i].value,
              color: colors[i % colors.length],
            );
          }),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════
//  BAR CHARTS
// ════════════════════════════════════════════════════════

class DevicesByBuildingBarChart extends StatelessWidget {
  final List<AnalyticsBarDatum> data;

  const DevicesByBuildingBarChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return _AdminBarChart(
      data: data,
      barColor: AppColors.accent,
      emptyText: AppLocalizations.of(context).isAr
          ? 'لا توجد بيانات مباني'
          : 'No building data',
    );
  }
}

class DevicesByTypeBarChart extends StatelessWidget {
  final List<AnalyticsBarDatum> data;

  const DevicesByTypeBarChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return _AdminBarChart(
      data: data,
      barColor: AppColors.info,
      emptyText: AppLocalizations.of(context).isAr
          ? 'لا توجد بيانات أنواع'
          : 'No type data',
    );
  }
}

class TechnicianPerformanceBarChart extends StatelessWidget {
  final List<AnalyticsBarDatum> data;

  const TechnicianPerformanceBarChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return _AdminBarChart(
      data: data,
      barColor: AppColors.success,
      height: 240,
      emptyText: AppLocalizations.of(context).isAr
          ? 'لا توجد بيانات فنيين'
          : 'No technician data',
    );
  }
}

class _AdminBarChart extends StatelessWidget {
  final List<AnalyticsBarDatum> data;
  final Color barColor;
  final double height;
  final String emptyText;

  const _AdminBarChart({
    required this.data,
    required this.barColor,
    required this.emptyText,
    this.height = 260,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _EmptyChartText(text: emptyText);
    }

    final cleanData = data.where((e) => e.value > 0).toList();

    if (cleanData.isEmpty) {
      return _EmptyChartText(text: emptyText);
    }

    final maxValue = cleanData
        .map((e) => e.value)
        .fold<double>(0, (prev, next) => next > prev ? next : prev);

    final maxY = maxValue <= 0 ? 1.0 : maxValue + 2;

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.borderLight,
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
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
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: AppText.caption.copyWith(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                reservedSize: 48,
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();

                  if (i < 0 || i >= cleanData.length) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: 62,
                      child: Text(
                        cleanData[i].label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppText.caption.copyWith(fontSize: 10),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: cleanData.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      barColor,
                      barColor.withOpacity(0.45),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
//  LINE CHARTS
// ════════════════════════════════════════════════════════

class TaskCompletionTrendChart extends StatelessWidget {
  final List<AnalyticsLineDatum> data;

  const TaskCompletionTrendChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return _AdminLineChart(
      data: data,
      colorA: AppColors.accent,
      colorB: AppColors.success,
      emptyText: AppLocalizations.of(context).isAr
          ? 'لا توجد بيانات إنجاز'
          : 'No completion trend data',
    );
  }
}

class InspectionsOverTimeChart extends StatelessWidget {
  final List<AnalyticsLineDatum> data;

  const InspectionsOverTimeChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return _AdminLineChart(
      data: data,
      colorA: AppColors.info,
      colorB: AppColors.accent,
      emptyText: AppLocalizations.of(context).isAr
          ? 'لا توجد بيانات تفتيش'
          : 'No inspection trend data',
    );
  }
}

class _AdminLineChart extends StatelessWidget {
  final List<AnalyticsLineDatum> data;
  final Color colorA;
  final Color colorB;
  final String emptyText;

  const _AdminLineChart({
    required this.data,
    required this.colorA,
    required this.colorB,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _EmptyChartText(text: emptyText);
    }

    final maxValue = data
        .map((e) => e.value)
        .fold<double>(0, (prev, next) => next > prev ? next : prev);

    final maxY = maxValue <= 0 ? 1.0 : maxValue + 1;

    return SizedBox(
      height: 230,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.borderLight,
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                reservedSize: 26,
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: AppText.caption.copyWith(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                reservedSize: 30,
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();

                  if (i < 0 || i >= data.length) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      data[i].label,
                      style: AppText.caption.copyWith(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.value);
              }).toList(),
              isCurved: true,
              barWidth: 4,
              isStrokeCapRound: true,
              gradient: LinearGradient(colors: [colorA, colorB]),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: colorA,
                    strokeWidth: 1,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    colorA.withOpacity(0.18),
                    Colors.transparent,
                  ],
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

// ════════════════════════════════════════════════════════
//  STACKED BAR CHART
// ════════════════════════════════════════════════════════

class TaskExecutionStackedChart extends StatelessWidget {
  final List<AnalyticsStackedDatum> data;

  const TaskExecutionStackedChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (data.isEmpty) {
      return _EmptyChartText(
        text: l.isAr ? 'لا توجد بيانات تنفيذ مهام' : 'No task execution data',
      );
    }

    final maxValue = data
        .map((e) => e.completed + e.inProgress + e.pending)
        .fold<double>(0, (prev, next) => next > prev ? next : prev);

    final maxY = maxValue <= 0 ? 1.0 : maxValue + 2;

    final completedTotal = data.fold<double>(0, (sum, e) => sum + e.completed).toInt();
    final inProgressTotal = data.fold<double>(0, (sum, e) => sum + e.inProgress).toInt();
    final pendingTotal = data.fold<double>(0, (sum, e) => sum + e.pending).toInt();

    return Column(
      children: [
        SizedBox(
          height: 260,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppColors.borderLight,
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    reservedSize: 26,
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: AppText.caption.copyWith(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    reservedSize: 38,
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();

                      if (i < 0 || i >= data.length) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          data[i].label,
                          style: AppText.caption.copyWith(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: data.asMap().entries.map((entry) {
                final item = entry.value;
                final pendingEnd = item.pending;
                final inProgressEnd = item.pending + item.inProgress;
                final completedEnd = item.pending + item.inProgress + item.completed;

                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: completedEnd,
                      width: 20,
                      borderRadius: BorderRadius.circular(7),
                      rodStackItems: [
                        BarChartRodStackItem(
                          0,
                          pendingEnd,
                          AppColors.warning,
                        ),
                        BarChartRodStackItem(
                          pendingEnd,
                          inProgressEnd,
                          AppColors.info,
                        ),
                        BarChartRodStackItem(
                          inProgressEnd,
                          completedEnd,
                          AppColors.success,
                        ),
                      ],
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnalyticsLegend(
          items: [
            LegendItemData(
              label: l.isAr ? 'مكتملة' : 'Completed',
              value: completedTotal,
              color: AppColors.success,
            ),
            LegendItemData(
              label: l.isAr ? 'جارية' : 'In Progress',
              value: inProgressTotal,
              color: AppColors.info,
            ),
            LegendItemData(
              label: l.isAr ? 'معلقة/متأخرة' : 'Pending/Overdue',
              value: pendingTotal,
              color: AppColors.warning,
            ),
          ],
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════
//  TASK CARD
// ════════════════════════════════════════════════════════

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
  });

  Color get _priorityColor {
    switch (task.priority.toUpperCase()) {
      case 'URGENT':
        return AppColors.error;
      case 'HIGH':
        return AppColors.warning;
      case 'MEDIUM':
        return AppColors.info;
      default:
        return AppColors.textHint;
    }
  }

  Color get _statusColor {
    switch (task.status.toUpperCase()) {
      case 'COMPLETED':
        return AppColors.success;
      case 'IN_PROGRESS':
        return AppColors.info;
      case 'OVERDUE':
        return AppColors.error;
      case 'PENDING':
        return AppColors.warning;
      case 'CANCELLED':
        return AppColors.textHint;
      default:
        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: task.isUrgent
                  ? AppColors.error.withOpacity(0.4)
                  : AppColors.border,
              width: task.isUrgent ? 1.5 : 1,
            ),
            boxShadow: task.isUrgent
                ? [
                    BoxShadow(
                      color: AppColors.error.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (task.isEmergency)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emergency_rounded,
                            size: 10,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            l.isAr ? 'طارئ' : 'EMERGENCY',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 9,
                              color: AppColors.error,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.priorityAr,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: _priorityColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.title,
                      style: AppText.bodyMed.copyWith(fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.statusAr,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: _statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (task.description.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  task.description,
                  style: AppText.small,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (task.assignedToName != null) ...[
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 13,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        task.assignedToName!,
                        style: AppText.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (task.deviceName != null) ...[
                    const Icon(
                      Icons.devices_rounded,
                      size: 13,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        task.deviceName!,
                        style: AppText.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (task.locationName != null) ...[
                    const Icon(
                      Icons.location_on_rounded,
                      size: 13,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        task.locationName!,
                        style: AppText.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Spacer(),
                  if (task.dueDate != null) ...[
                    const Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                      style: AppText.caption,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
//  TASK DETAIL SHEET
// ════════════════════════════════════════════════════════

class TaskDetailSheet extends ConsumerWidget {
  final TaskModel task;
  final bool isViewer;
  final Future<void> Function(String newStatus)? onStatusChanged;
  final Future<void> Function(String technicianId)? onReassign;

  const TaskDetailSheet({
    super.key,
    required this.task,
    this.isViewer = false,
    this.onStatusChanged,
    this.onReassign,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final techs = ref.watch(techniciansProvider).valueOrNull ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      minChildSize: 0.42,
      builder: (_, ctrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceGrey,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const _SheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    if (task.isEmergency)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.emergency_rounded,
                              size: 14,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l.isAr ? 'طارئ' : 'EMERGENCY',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                color: AppColors.error,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: Text(
                        l.isAr ? 'تفاصيل المهمة' : 'Task Details',
                        style: AppText.h3,
                      ),
                    ),
                    _StatusChip(task: task),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _DetailCard(
                      children: [
                        _DetailRow(l.isAr ? 'العنوان' : 'Title', task.title),
                        if (task.description.trim().isNotEmpty)
                          _DetailRow(
                            l.isAr ? 'الوصف' : 'Description',
                            task.description,
                          ),
                        _DetailRow(
                          l.isAr ? 'الأولوية' : 'Priority',
                          task.priorityAr,
                        ),
                        _DetailRow(
                          l.isAr ? 'الحالة' : 'Status',
                          task.statusAr,
                        ),
                        if (task.dueDate != null)
                          _DetailRow(
                            l.isAr ? 'موعد التنفيذ' : 'Due Date',
                            '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                          ),
                        _DetailRow(
                          l.isAr ? 'تاريخ الإنشاء' : 'Created At',
                          '${task.createdAt.day}/${task.createdAt.month}/${task.createdAt.year}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (task.assignedToName != null ||
                        task.assignedToEmail != null ||
                        task.assignedToId != null)
                      _DetailCard(
                        children: [
                          if (task.assignedToName != null)
                            _DetailRow(
                              l.isAr ? 'الفني المكلف' : 'Technician',
                              task.assignedToName!,
                            ),
                          if (task.assignedToEmail != null)
                            _DetailRow(
                              l.isAr ? 'الإيميل' : 'Email',
                              task.assignedToEmail!,
                            ),
                          if (task.assignedToId != null)
                            _DetailRow('ID', task.assignedToId!),
                        ],
                      ),
                    const SizedBox(height: 12),
                    if (task.deviceName != null ||
                        task.deviceCode != null ||
                        task.locationName != null)
                      _DetailCard(
                        children: [
                          if (task.deviceName != null)
                            _DetailRow(
                              l.isAr ? 'الجهاز' : 'Device',
                              task.deviceName!,
                            ),
                          if (task.deviceCode != null)
                            _DetailRow(
                              l.isAr ? 'الكود' : 'Code',
                              task.deviceCode!,
                            ),
                          if (task.locationName != null)
                            _DetailRow(
                              l.isAr ? 'الموقع' : 'Location',
                              task.locationName!,
                            ),
                        ],
                      ),
                    if (task.notes?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      _NoteCard(
                        label: l.isAr ? 'الملاحظات' : 'Notes',
                        text: task.notes!,
                      ),
                    ],
                    if (!isViewer && onStatusChanged != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        l.isAr ? 'تغيير الحالة:' : 'Change Status:',
                        style: AppText.small.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ActionStatusButton(
                            label: l.isAr ? 'جارية' : 'In Progress',
                            color: AppColors.info,
                            onTap: () async {
                              await onStatusChanged!('IN_PROGRESS');
                              if (context.mounted) Navigator.pop(context);
                            },
                          ),
                          _ActionStatusButton(
                            label: l.isAr ? 'مكتملة' : 'Completed',
                            color: AppColors.success,
                            onTap: () async {
                              await onStatusChanged!('COMPLETED');
                              if (context.mounted) Navigator.pop(context);
                            },
                          ),
                          _ActionStatusButton(
                            label: l.isAr ? 'إلغاء' : 'Cancel',
                            color: AppColors.error,
                            onTap: () async {
                              await onStatusChanged!('CANCELLED');
                              if (context.mounted) Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ],
                    if (!isViewer && onReassign != null && techs.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        l.isAr ? 'إعادة تعيين لفني آخر:' : 'Reassign to Technician:',
                        style: AppText.small.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: techs.any((t) => t.id == task.assignedToId)
                            ? task.assignedToId
                            : null,
                        decoration: InputDecoration(
                          labelText: l.isAr ? 'اختر الفني' : 'Select Technician',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: techs.map((t) {
                          return DropdownMenuItem(
                            value: t.id,
                            child: Text(
                              '${t.fullName} (${t.username})',
                              style: AppText.body,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (techId) async {
                          if (techId != null && techId != task.assignedToId) {
                            await onReassign!(techId);
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionStatusButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionStatusButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final TaskModel task;

  const _StatusChip({
    required this.task,
  });

  Color get _color {
    switch (task.status.toUpperCase()) {
      case 'COMPLETED':
        return AppColors.success;
      case 'IN_PROGRESS':
        return AppColors.info;
      case 'OVERDUE':
        return AppColors.error;
      case 'PENDING':
        return AppColors.warning;
      case 'CANCELLED':
        return AppColors.textHint;
      default:
        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Text(
        task.statusAr,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          color: _color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
//  INSPECTION CARD
// ════════════════════════════════════════════════════════

class InspectionCard extends StatelessWidget {
  final InspectionDetail inspection;
  final VoidCallback onTap;

  const InspectionCard({
    super.key,
    required this.inspection,
    required this.onTap,
  });

  Color get _color {
    switch (inspection.inspectionStatus.toUpperCase()) {
      case 'OK':
        return AppColors.success;
      case 'NOT_OK':
        return AppColors.error;
      case 'PARTIAL':
        return AppColors.warning;
      case 'NOT_REACHABLE':
        return AppColors.textHint;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _color.withOpacity(0.25)),
                ),
                child: Icon(Icons.computer_rounded, color: _color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inspection.deviceName,
                      style: AppText.bodyMed.copyWith(fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      inspection.technicianName,
                      style: AppText.small,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 11,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            inspection.locationText,
                            style: AppText.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      inspection.statusAr,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: _color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${inspection.inspectedAt.day}/${inspection.inspectedAt.month}',
                    style: AppText.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
//  INSPECTION DETAIL SHEET
// ════════════════════════════════════════════════════════

class InspectionDetailSheet extends StatelessWidget {
  final InspectionDetail inspection;

  const InspectionDetailSheet({
    super.key,
    required this.inspection,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceGrey,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const _SheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.isAr ? 'تفاصيل التفتيش' : 'Inspection Details',
                        style: AppText.h3,
                      ),
                    ),
                    Text(
                      inspection.reportNumber,
                      style: AppText.small.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _DetailCard(
                      children: [
                        _DetailRow(l.isAr ? 'الجهاز' : 'Device', inspection.deviceName),
                        _DetailRow(l.isAr ? 'الكود' : 'Code', inspection.deviceCode),
                        _DetailRow(l.isAr ? 'الموقع' : 'Location', inspection.locationText),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _DetailCard(
                      children: [
                        _DetailRow(
                          l.isAr ? 'الفني' : 'Technician',
                          inspection.technicianName,
                        ),
                        _DetailRow(
                          l.isAr ? 'الحالة' : 'Status',
                          inspection.statusAr,
                        ),
                        _DetailRow(
                          l.isAr ? 'التاريخ' : 'Date',
                          '${inspection.inspectedAt.day}/${inspection.inspectedAt.month}/${inspection.inspectedAt.year}',
                        ),
                        _DetailRow(
                          l.isAr ? 'الوقت' : 'Time',
                          '${inspection.inspectedAt.hour.toString().padLeft(2, '0')}:${inspection.inspectedAt.minute.toString().padLeft(2, '0')}',
                        ),
                        _DetailRow(
                          'GPS',
                          '${inspection.latitude.toStringAsFixed(4)}, ${inspection.longitude.toStringAsFixed(4)}',
                        ),
                      ],
                    ),
                    if (inspection.notes?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      _NoteCard(
                        label: l.isAr ? 'الملاحظات' : 'Notes',
                        text: inspection.notes!,
                      ),
                    ],
                    if (inspection.issueReason?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      _NoteCard(
                        label: l.isAr ? 'سبب المشكلة' : 'Issue Reason',
                        text: inspection.issueReason!,
                        isWarning: true,
                      ),
                    ],
                    if (inspection.imageUrl != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          inspection.imageUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppColors.borderLight,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.image_rounded,
                                  size: 40,
                                  color: AppColors.textHint,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════
//  GLASS CARD
// ════════════════════════════════════════════════════════

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final List<Color>? gradientColors;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors ??
              [
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.02),
              ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ════════════════════════════════════════════════════════
//  SHIMMER WIDGETS
// ════════════════════════════════════════════════════════

class AdminShimmerCard extends StatelessWidget {
  const AdminShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class AdminShimmerList extends StatelessWidget {
  final int count;

  const AdminShimmerList({
    super.key,
    this.count = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
//  SHARED HELPERS
// ════════════════════════════════════════════════════════

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;

  const _DetailCard({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: children.asMap().entries.map((e) {
          return Column(
            children: [
              e.value,
              if (e.key < children.length - 1)
                const Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: AppColors.border,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(label, style: AppText.small),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: AppText.bodyMed.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.end,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final String label;
  final String text;
  final bool isWarning;

  const _NoteCard({
    required this.label,
    required this.text,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWarning ? AppColors.errorLight : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWarning ? AppColors.error.withOpacity(0.3) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.small.copyWith(
              fontWeight: FontWeight.w700,
              color: isWarning ? AppColors.error : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: AppText.body.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _EmptyChartText extends StatelessWidget {
  final String text;

  const _EmptyChartText({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          text,
          style: AppText.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String _deviceStatusLabel(String value, bool isAr) {
  final v = value.toUpperCase();

  if (!isAr) {
    switch (v) {
      case 'OK':
        return 'Healthy';
      case 'MAINTENANCE':
      case 'NEEDS_MAINTENANCE':
      case 'UNDER_MAINTENANCE':
      case 'PARTIAL':
        return 'Maintenance';
      case 'OUT_OF_SERVICE':
      case 'NOT_OK':
      case 'NOT_REACHABLE':
        return 'Out of service';
      default:
        return value;
    }
  }

  switch (v) {
    case 'OK':
      return 'سليم';
    case 'MAINTENANCE':
    case 'NEEDS_MAINTENANCE':
    case 'UNDER_MAINTENANCE':
    case 'PARTIAL':
      return 'صيانة';
    case 'OUT_OF_SERVICE':
    case 'NOT_OK':
    case 'NOT_REACHABLE':
      return 'خارج الخدمة';
    default:
      return value;
  }
}

String _taskStatusLabel(String value, bool isAr) {
  final v = value.toUpperCase();

  if (!isAr) {
    switch (v) {
      case 'PENDING':
        return 'Pending';
      case 'IN_PROGRESS':
        return 'In progress';
      case 'COMPLETED':
        return 'Completed';
      case 'OVERDUE':
        return 'Overdue';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return value;
    }
  }

  switch (v) {
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