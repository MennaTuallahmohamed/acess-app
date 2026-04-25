import 'package:access_track/app_localizations.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:access_track/core/modals/models.dart';
import 'package:access_track/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MonthlyReportsScreen extends StatefulWidget {
  final List<ReportModel> reports;
  final String inspectorName;
  final String region;

  const MonthlyReportsScreen({
    super.key,
    required this.reports,
    required this.inspectorName,
    required this.region,
  });

  @override
  State<MonthlyReportsScreen> createState() => _MonthlyReportsScreenState();
}

class _MonthlyReportsScreenState extends State<MonthlyReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _selectedMonth = '';
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _selectedMonth =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<ReportModel> get _monthReports {
    final list = widget.reports.where((r) {
      final key =
          '${r.createdAt.year}-${r.createdAt.month.toString().padLeft(2, '0')}';
      return key == _selectedMonth;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  int get _total => _monthReports.length;
  int get _good => _monthReports.where((r) => r.result == 'good').length;
  int get _maint =>
      _monthReports.where((r) => r.result == 'maintenance' || r.result == 'minor').length;
  int get _faulty => _monthReports.where((r) => r.result == 'faulty').length;
  int get _review => _monthReports.where((r) => r.result == 'review').length;
  double get _rate => _total == 0 ? 0 : (_good / _total * 100);
  double get _dailyAvg => _total == 0 ? 0 : (_total / 30);

  Map<String, int> get _byType {
    final m = <String, int>{};
    for (final r in _monthReports) {
      m[r.deviceType] = (m[r.deviceType] ?? 0) + 1;
    }
    return m;
  }

  String _monthChipLabel(DateTime dt, AppLocalizations l) {
    final namesAr = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    final namesEn = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final monthName = l.isAr ? namesAr[dt.month - 1] : namesEn[dt.month - 1];
    return '$monthName ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.monthlyReports,
                      style: AppText.h3.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.inspectorName,
                      style: AppText.small.copyWith(color: Colors.white60),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        itemCount: 6,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final dt = DateTime(now.year, now.month - i);
                          final key =
                              '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
                          final selected = key == _selectedMonth;

                          return GestureDetector(
                            onTap: () => setState(() => _selectedMonth = key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.accent
                                    : Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _monthChipLabel(dt, l),
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: selected
                                      ? AppColors.primary
                                      : Colors.white70,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: AppColors.primary,
                child: TabBar(
                  controller: _tabs,
                  indicatorColor: AppColors.accent,
                  indicatorWeight: 3,
                  labelColor: AppColors.accent,
                  unselectedLabelColor: Colors.white54,
                  tabs: [
                    Tab(text: l.monthlyOverview),
                    Tab(text: l.allTasks),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _OverviewTab(
              total: _total,
              good: _good,
              maint: _maint,
              faulty: _faulty,
              review: _review,
              rate: _rate,
              dailyAvg: _dailyAvg,
              byType: _byType,
              l: l,
            ),
            _TasksTab(
              reports: _monthReports,
              expandedId: _expandedId,
              onToggle: (id) => setState(
                () => _expandedId = _expandedId == id ? null : id,
              ),
              l: l,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final int total;
  final int good;
  final int maint;
  final int faulty;
  final int review;
  final double rate;
  final double dailyAvg;
  final Map<String, int> byType;
  final AppLocalizations l;

  const _OverviewTab({
    required this.total,
    required this.good,
    required this.maint,
    required this.faulty,
    required this.review,
    required this.rate,
    required this.dailyAvg,
    required this.byType,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                value: total.toString(),
                label: l.totalInspected,
                color: AppColors.info,
                icon: Icons.fact_check_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                value: '${rate.toStringAsFixed(0)}%',
                label: l.completionRate,
                color: AppColors.success,
                icon: Icons.trending_up_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                value: dailyAvg.toStringAsFixed(1),
                label: l.avgPerDay,
                color: AppColors.accent,
                icon: Icons.schedule_rounded,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms),

        const SizedBox(height: 20),

        _SectionCard(
          title: l.inspByStatus,
          child: Column(
            children: [
              _StatusBar(
                label: l.statusGood,
                value: good,
                total: total,
                color: AppColors.success,
              ),
              const SizedBox(height: 10),
              _StatusBar(
                label: l.statusMaint,
                value: maint,
                total: total,
                color: AppColors.warning,
              ),
              const SizedBox(height: 10),
              _StatusBar(
                label: l.isAr ? 'عطل' : 'Faulty',
                value: faulty,
                total: total,
                color: AppColors.error,
              ),
              const SizedBox(height: 10),
              _StatusBar(
                label: l.isAr ? 'تحت المراجعة' : 'In Review',
                value: review,
                total: total,
                color: AppColors.info,
              ),
            ],
          ),
        ).animate(delay: 80.ms).fadeIn().slideY(begin: 0.06),

        const SizedBox(height: 16),

        if (byType.isNotEmpty)
          _SectionCard(
            title: l.inspByType,
            child: Column(
              children: byType.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TypeBar(
                    label: l.deviceTypeLabel(entry.key),
                    value: entry.value,
                    total: total,
                  ),
                );
              }).toList(),
            ),
          ).animate(delay: 120.ms).fadeIn().slideY(begin: 0.06),

        const SizedBox(height: 80),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _KpiCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value, style: AppText.h3.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(label, style: AppText.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _StatusBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : value / total;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: AppText.small)),
            Text('$value', style: AppText.bodyMed),
            const SizedBox(width: 8),
            Text(
              '(${(pct * 100).toStringAsFixed(0)}%)',
              style: AppText.caption,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: AppColors.borderLight,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _TypeBar extends StatelessWidget {
  final String label;
  final int value;
  final int total;

  const _TypeBar({
    required this.label,
    required this.value,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : value / total;

    return Row(
      children: [
        Expanded(flex: 3, child: Text(label, style: AppText.small)),
        Expanded(
          flex: 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.borderLight,
              valueColor: const AlwaysStoppedAnimation(AppColors.info),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            style: AppText.smallBold,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.h4),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _TasksTab extends StatelessWidget {
  final List<ReportModel> reports;
  final String? expandedId;
  final Function(String) onToggle;
  final AppLocalizations l;

  const _TasksTab({
    required this.reports,
    required this.expandedId,
    required this.onToggle,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_rounded,
              size: 56,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              l.noResults,
              style: AppText.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final r = reports[i];
        final isExpanded = expandedId == r.id;

        return _TaskCard(
          report: r,
          isExpanded: isExpanded,
          index: i + 1,
          onToggle: () => onToggle(r.id),
          l: l,
        )
            .animate(delay: Duration(milliseconds: i * 40))
            .fadeIn(duration: 260.ms)
            .slideY(begin: 0.04);
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final ReportModel report;
  final bool isExpanded;
  final int index;
  final VoidCallback onToggle;
  final AppLocalizations l;

  const _TaskCard({
    required this.report,
    required this.isExpanded,
    required this.index,
    required this.onToggle,
    required this.l,
  });

  String _fmtDate(DateTime d) {
    final monthsAr = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    final monthsEn = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final months = l.isAr ? monthsAr : monthsEn;
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _fmtTime(DateTime d) {
    final suffix = d.hour < 12 ? (l.isAr ? 'ص' : 'AM') : (l.isAr ? 'م' : 'PM');
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $suffix';
  }

  String _extractIssueCode(String notes) {
    final match = RegExp(r'Issue Code:\s*(.+)').firstMatch(notes);
    return match?.group(1)?.trim() ?? '';
  }

  String _extractIssueTitle(String notes) {
    final match = RegExp(r'Issue Title:\s*(.+)').firstMatch(notes);
    return match?.group(1)?.trim() ?? '';
  }

  String _extractCompletedIds(String notes) {
    final match = RegExp(r'Completed Steps IDs:\s*(.+)').firstMatch(notes);
    return match?.group(1)?.trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final issueCode = _extractIssueCode(report.notes);
    final issueTitle = _extractIssueTitle(report.notes);
    final completedIds = _extractCompletedIds(report.notes);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? AppColors.accent : AppColors.border,
          width: isExpanded ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Stack(
                    children: [
                      DeviceTypeIcon(type: report.deviceType, size: 46),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              '$index',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.deviceName,
                          style: AppText.bodyMed,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          report.reportNumber,
                          style: AppText.caption.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_fmtDate(report.createdAt)} — ${_fmtTime(report.createdAt)}',
                          style: AppText.caption,
                        ),
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
                      AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 260),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                const Divider(height: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _DetailRow(l.deviceName, report.deviceName, isCode: false),
                      _DetailRow(l.deviceCode, report.deviceCode, isCode: true),
                      _DetailRow(l.inspDate, _fmtDate(report.createdAt)),
                      _DetailRow(l.inspTime, _fmtTime(report.createdAt)),
                      _DetailRow(l.inspector, report.inspectorName),
                      _DetailRow(l.inspLocation, report.locationText),
                      _DetailRow(
                        l.inspResult,
                        l.statusLabel(report.result),
                        isStatus: true,
                        statusVal: report.result,
                      ),
                      _DetailRow(
                        l.gpsCoords,
                        '${report.latitude.toStringAsFixed(4)}°N, ${report.longitude.toStringAsFixed(4)}°E',
                        isCode: true,
                      ),
                      if (issueCode.isNotEmpty)
                        _DetailRow(
                          l.isAr ? 'كود المشكلة' : 'Issue Code',
                          issueCode,
                          isCode: true,
                        ),
                      if (issueTitle.isNotEmpty)
                        _DetailRow(
                          l.isAr ? 'المشكلة' : 'Issue',
                          issueTitle,
                        ),
                      if (completedIds.isNotEmpty)
                        _DetailRow(
                          l.isAr ? 'خطوات تم تنفيذها' : 'Completed Steps',
                          completedIds,
                          isCode: true,
                        ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.notesLbl,
                              style: AppText.small.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              report.notes.isEmpty ? l.noNotes : report.notes,
                              style: report.notes.isEmpty
                                  ? AppText.caption
                                  : AppText.body,
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isCode;
  final bool isStatus;
  final String? statusVal;

  const _DetailRow(
    this.label,
    this.value, {
    this.isCode = false,
    this.isStatus = false,
    this.statusVal,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: AppText.small),
          ),
          Expanded(
            child: isStatus
                ? Align(
                    alignment: Alignment.centerRight,
                    child: StatusBadge(
                      label: value,
                      type: statusFromString(statusVal ?? ''),
                      isSmall: true,
                    ),
                  )
                : Text(
                    value.isEmpty ? '—' : value,
                    textAlign: TextAlign.end,
                    style: isCode
                        ? const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          )
                        : AppText.bodyMed,
                  ),
          ),
        ],
      ),
    );
  }
}