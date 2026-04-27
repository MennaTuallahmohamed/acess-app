import 'package:access_track/admin/admin_models.dart';
import 'package:access_track/admin/admin_providers.dart';
import 'package:access_track/app_localizations.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ViewerInspectionInfoScreen extends ConsumerStatefulWidget {
  const ViewerInspectionInfoScreen({super.key});

  @override
  ConsumerState<ViewerInspectionInfoScreen> createState() =>
      _ViewerInspectionInfoScreenState();
}

class _ViewerInspectionInfoScreenState
    extends ConsumerState<ViewerInspectionInfoScreen> {
  String _search = '';
  String? _statusFilter;

  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(monthlyInspectionsProvider);
    ref.invalidate(adminStatsProvider);
  }

  List<InspectionDetail> _applyFilters(List<InspectionDetail> list) {
    final q = _search.trim().toLowerCase();

    final filtered = list.where((item) {
      if (_statusFilter != null &&
          item.inspectionStatus.toUpperCase() != _statusFilter) {
        return false;
      }

      if (q.isNotEmpty) {
        final haystack = [
          item.reportNumber,
          item.deviceName,
          item.deviceCode,
          item.locationText,
          item.inspectionStatus,
          item.statusAr,
          item.notes ?? '',
          item.issueReason ?? '',
        ].join(' ').toLowerCase();

        if (!haystack.contains(q)) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) => b.inspectedAt.compareTo(a.inspectedAt));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = AppLocalizations.of(context).isAr;
    final inspectionsAsync = ref.watch(monthlyInspectionsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: SafeArea(
        bottom: false,
        child: inspectionsAsync.when(
          loading: () => const _LoadingView(),
          error: (e, _) => _ErrorView(
            message: e.toString(),
            onRetry: _refresh,
          ),
          data: (items) {
            final filtered = _applyFilters(items);
            final stats = _InspectionStats.from(items);

            return RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () async => _refresh(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _Header(
                      isAr: isAr,
                      onBack: () => Navigator.maybePop(context),
                      onRefresh: _refresh,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ExecutiveInspectionSummary(
                            stats: stats,
                            isAr: isAr,
                          ).animate().fadeIn().slideY(begin: 0.05),
                          const SizedBox(height: 14),
                          _StatusGrid(
                            stats: stats,
                            isAr: isAr,
                          ).animate(delay: 80.ms).fadeIn(),
                          const SizedBox(height: 14),
                          _FiltersPanel(
                            isAr: isAr,
                            controller: _searchCtrl,
                            search: _search,
                            selectedStatus: _statusFilter,
                            onSearch: (v) => setState(() => _search = v),
                            onStatus: (v) => setState(() => _statusFilter = v),
                            onClear: () {
                              setState(() {
                                _search = '';
                                _statusFilter = null;
                                _searchCtrl.clear();
                              });
                            },
                          ).animate(delay: 120.ms).fadeIn(),
                          const SizedBox(height: 18),
                          Text(
                            isAr ? 'سجل التفتيشات' : 'Inspection Register',
                            style: AppText.h4.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(isAr: isAr),
                    )
                  else
                    SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            index == 0 ? 0 : 0,
                            16,
                            index == filtered.length - 1 ? 90 : 0,
                          ),
                          child: _InspectionInfoCard(
                            inspection: item,
                            isAr: isAr,
                            index: index,
                            onTap: () => _openDetails(context, item, isAr),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openDetails(BuildContext context, InspectionDetail item, bool isAr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InspectionInfoSheet(
        inspection: item,
        isAr: isAr,
      ),
    );
  }
}

class _InspectionStats {
  final int total;
  final int ok;
  final int notOk;
  final int partial;
  final int notReachable;
  final int today;
  final int withNotes;

  const _InspectionStats({
    required this.total,
    required this.ok,
    required this.notOk,
    required this.partial,
    required this.notReachable,
    required this.today,
    required this.withNotes,
  });

  factory _InspectionStats.from(List<InspectionDetail> items) {
    final now = DateTime.now();

    int count(String status) => items
        .where((e) => e.inspectionStatus.toUpperCase() == status)
        .length;

    final today = items.where((e) {
      final d = e.inspectedAt;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).length;

    final withNotes = items.where((e) {
      return (e.notes ?? '').trim().isNotEmpty ||
          (e.issueReason ?? '').trim().isNotEmpty;
    }).length;

    return _InspectionStats(
      total: items.length,
      ok: count('OK'),
      notOk: count('NOT_OK'),
      partial: count('PARTIAL'),
      notReachable: count('NOT_REACHABLE'),
      today: today,
      withNotes: withNotes,
    );
  }

  double get healthRate => total == 0 ? 0 : ok / total;
  double get issueRate => total == 0 ? 0 : (notOk + partial) / total;
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E3A8A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          _HeaderButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: 10),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: const Icon(
              Icons.fact_check_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'موقف التفتيش الميداني' : 'Field Inspection Status',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Cairo',
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isAr
                      ? 'بيانات تشغيلية معتمدة لعرض الموقف العام'
                      : 'Operational data for command-level visibility',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.70),
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _HeaderButton(
            icon: Icons.refresh_rounded,
            onTap: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _ExecutiveInspectionSummary extends StatelessWidget {
  final _InspectionStats stats;
  final bool isAr;

  const _ExecutiveInspectionSummary({
    required this.stats,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: CustomPaint(
              painter: _RingPainter(
                value: stats.healthRate,
                color: AppColors.success,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(stats.healthRate * 100).round()}%',
                      style: AppText.h3.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      isAr ? 'سليم' : 'OK',
                      style: AppText.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
                  isAr ? 'ملخص موقف التفتيش' : 'Inspection Situation Brief',
                  style: AppText.h4.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAr
                      ? 'يعرض هذا الجزء نتائج التفتيشات المسجلة، حالة الأجهزة، ونسبة الملاحظات الفنية بدون إظهار بيانات شخصية.'
                      : 'This section summarizes registered inspections, device condition, and issue indicators without personal data.',
                  style: AppText.caption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(
                      text: '${stats.total} ${isAr ? 'تفتيش' : 'records'}',
                      color: AppColors.primary,
                    ),
                    _Pill(
                      text: '${stats.today} ${isAr ? 'اليوم' : 'today'}',
                      color: AppColors.info,
                    ),
                    _Pill(
                      text: '${stats.withNotes} ${isAr ? 'بملاحظات' : 'with notes'}',
                      color: AppColors.warning,
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

class _StatusGrid extends StatelessWidget {
  final _InspectionStats stats;
  final bool isAr;

  const _StatusGrid({
    required this.stats,
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
            _MiniMetricCard(
              width: width,
              title: isAr ? 'سليم' : 'OK',
              value: stats.ok,
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
            ),
            _MiniMetricCard(
              width: width,
              title: isAr ? 'غير سليم' : 'Not OK',
              value: stats.notOk,
              icon: Icons.cancel_rounded,
              color: AppColors.error,
            ),
            _MiniMetricCard(
              width: width,
              title: isAr ? 'جزئي' : 'Partial',
              value: stats.partial,
              icon: Icons.pending_rounded,
              color: AppColors.warning,
            ),
            _MiniMetricCard(
              width: width,
              title: isAr ? 'غير متاح' : 'Unreachable',
              value: stats.notReachable,
              icon: Icons.signal_wifi_bad_rounded,
              color: Colors.blueGrey,
            ),
          ],
        );
      },
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  final double width;
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _MiniMetricCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.16)),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: AppText.h3.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersPanel extends StatelessWidget {
  final bool isAr;
  final TextEditingController controller;
  final String search;
  final String? selectedStatus;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onStatus;
  final VoidCallback onClear;

  const _FiltersPanel({
    required this.isAr,
    required this.controller,
    required this.search,
    required this.selectedStatus,
    required this.onSearch,
    required this.onStatus,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: isAr
                  ? 'بحث برقم التقرير، الجهاز، الموقع، الحالة...'
                  : 'Search report, device, location, status...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: AppColors.surfaceGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _StatusChip(
                  label: isAr ? 'الكل' : 'All',
                  selected: selectedStatus == null,
                  color: AppColors.primary,
                  onTap: () => onStatus(null),
                ),
                _StatusChip(
                  label: isAr ? 'سليم' : 'OK',
                  selected: selectedStatus == 'OK',
                  color: AppColors.success,
                  onTap: () => onStatus('OK'),
                ),
                _StatusChip(
                  label: isAr ? 'غير سليم' : 'Not OK',
                  selected: selectedStatus == 'NOT_OK',
                  color: AppColors.error,
                  onTap: () => onStatus('NOT_OK'),
                ),
                _StatusChip(
                  label: isAr ? 'جزئي' : 'Partial',
                  selected: selectedStatus == 'PARTIAL',
                  color: AppColors.warning,
                  onTap: () => onStatus('PARTIAL'),
                ),
                _StatusChip(
                  label: isAr ? 'غير متاح' : 'Unreachable',
                  selected: selectedStatus == 'NOT_REACHABLE',
                  color: Colors.blueGrey,
                  onTap: () => onStatus('NOT_REACHABLE'),
                ),
                if (search.trim().isNotEmpty || selectedStatus != null)
                  _StatusChip(
                    label: isAr ? 'مسح' : 'Clear',
                    selected: false,
                    color: Colors.black54,
                    onTap: onClear,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? color : color.withOpacity(0.09),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withOpacity(0.24)),
          ),
          child: Text(
            label,
            style: AppText.caption.copyWith(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _InspectionInfoCard extends StatelessWidget {
  final InspectionDetail inspection;
  final bool isAr;
  final int index;
  final VoidCallback onTap;

  const _InspectionInfoCard({
    required this.inspection,
    required this.isAr,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(inspection.inspectionStatus);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.18)),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 118,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(18),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              inspection.deviceName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.bodyMed.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          _Pill(
                            text: isAr
                                ? _statusAr(inspection.inspectionStatus)
                                : _statusEn(inspection.inspectionStatus),
                            color: color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          _MiniInfo(
                            icon: Icons.confirmation_number_rounded,
                            text: inspection.reportNumber,
                          ),
                          _MiniInfo(
                            icon: Icons.qr_code_rounded,
                            text: inspection.deviceCode,
                          ),
                          if (inspection.locationText.trim().isNotEmpty)
                            _MiniInfo(
                              icon: Icons.place_rounded,
                              text: inspection.locationText,
                            ),
                          _MiniInfo(
                            icon: Icons.event_available_rounded,
                            text: _dateTime(inspection.inspectedAt),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        _briefText(inspection, isAr),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsetsDirectional.only(end: 8),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFCBD5E1),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: (index * 25).clamp(0, 240)))
        .fadeIn(duration: 250.ms)
        .slideY(begin: 0.04);
  }
}

class _InspectionInfoSheet extends StatelessWidget {
  final InspectionDetail inspection;
  final bool isAr;

  const _InspectionInfoSheet({
    required this.inspection,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(inspection.inspectionStatus);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.94,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.18)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.fact_check_rounded,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inspection.deviceName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.h4.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${inspection.reportNumber} • ${isAr ? _statusAr(inspection.inspectionStatus) : _statusEn(inspection.inspectionStatus)}',
                            style: AppText.caption.copyWith(
                              color: color,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _DetailBlock(
                title: isAr ? 'بيانات التفتيش' : 'Inspection Information',
                icon: Icons.assignment_turned_in_rounded,
                children: [
                  _InfoRow(label: isAr ? 'رقم التقرير' : 'Report No.', value: inspection.reportNumber),
                  _InfoRow(label: isAr ? 'الحالة' : 'Status', value: isAr ? _statusAr(inspection.inspectionStatus) : _statusEn(inspection.inspectionStatus)),
                  _InfoRow(label: isAr ? 'تاريخ التفتيش' : 'Inspection Date', value: _dateTime(inspection.inspectedAt)),
                  _InfoRow(label: isAr ? 'الجهاز' : 'Device', value: inspection.deviceName),
                  _InfoRow(label: isAr ? 'كود الجهاز' : 'Device Code', value: inspection.deviceCode),
                  _InfoRow(label: isAr ? 'الموقع' : 'Location', value: inspection.locationText),
                ],
              ),
              const SizedBox(height: 12),
              _DetailBlock(
                title: isAr ? 'ملخص الملاحظات' : 'Observation Summary',
                icon: Icons.notes_rounded,
                children: [
                  _InfoRow(
                    label: isAr ? 'سبب المشكلة' : 'Issue Reason',
                    value: (inspection.issueReason ?? '').trim().isEmpty
                        ? (isAr ? 'لا يوجد' : 'None')
                        : inspection.issueReason!,
                  ),
                  _InfoRow(
                    label: isAr ? 'ملاحظات' : 'Notes',
                    value: (inspection.notes ?? '').trim().isEmpty
                        ? (isAr ? 'لا توجد ملاحظات' : 'No notes')
                        : inspection.notes!,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.info.withOpacity(0.16)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.privacy_tip_rounded,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isAr
                            ? 'تم إخفاء بيانات الأفراد والصور الشخصية في هذه الواجهة، ويتم عرض معلومات التفتيش التشغيلية فقط.'
                            : 'Personnel data and personal photos are hidden in this interface; only operational inspection information is displayed.',
                        style: AppText.caption.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.w800,
                          height: 1.4,
                        ),
                      ),
                    ),
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

class _DetailBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _DetailBlock({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: AppText.bodyMed.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppText.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value.trim().isEmpty ? '-' : value,
              textAlign: TextAlign.end,
              style: AppText.caption.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniInfo({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({
    required this.text,
    required this.color,
  });

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
        style: AppText.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10.5,
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, i) {
        return Container(
          height: i == 0 ? 180 : 110,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
              duration: 900.ms,
            );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
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
                style: AppText.bodyMed.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isAr;

  const _EmptyState({required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 58, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 10),
            Text(
              isAr ? 'لا توجد بيانات مطابقة' : 'No matching data',
              style: AppText.bodyMed.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;

  const _RingPainter({
    required this.value,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final bg = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.1415926535 / 2,
      value.clamp(0.0, 1.0) * 2 * 3.1415926535,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}

Color _statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'OK':
      return AppColors.success;
    case 'NOT_OK':
      return AppColors.error;
    case 'PARTIAL':
      return AppColors.warning;
    case 'NOT_REACHABLE':
      return Colors.blueGrey;
    default:
      return AppColors.info;
  }
}

String _statusAr(String status) {
  switch (status.toUpperCase()) {
    case 'OK':
      return 'سليم';
    case 'NOT_OK':
      return 'غير سليم';
    case 'PARTIAL':
      return 'جزئي';
    case 'NOT_REACHABLE':
      return 'غير متاح';
    default:
      return status;
  }
}

String _statusEn(String status) {
  switch (status.toUpperCase()) {
    case 'OK':
      return 'OK';
    case 'NOT_OK':
      return 'Not OK';
    case 'PARTIAL':
      return 'Partial';
    case 'NOT_REACHABLE':
      return 'Unreachable';
    default:
      return status;
  }
}

String _dateTime(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

String _briefText(InspectionDetail inspection, bool isAr) {
  final issue = (inspection.issueReason ?? '').trim();
  final notes = (inspection.notes ?? '').trim();

  if (issue.isNotEmpty) {
    return isAr ? 'ملاحظة فنية: $issue' : 'Technical observation: $issue';
  }

  if (notes.isNotEmpty) {
    return isAr ? 'ملاحظات: $notes' : 'Notes: $notes';
  }

  return isAr ? 'لا توجد ملاحظات مسجلة' : 'No recorded notes';
}
