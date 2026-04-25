import 'dart:math' as math;

import 'package:access_track/admin/admin_models.dart';
import 'package:access_track/admin/admin_providers.dart';
import 'package:access_track/app_localizations.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminInspectionsScreen extends ConsumerStatefulWidget {
  const AdminInspectionsScreen({super.key});

  @override
  ConsumerState<AdminInspectionsScreen> createState() =>
      _AdminInspectionsScreenState();
}

class _AdminInspectionsScreenState extends ConsumerState<AdminInspectionsScreen> {
  String? _techFilter;
  String? _locFilter;
  String? _statusFilter;
  String _search = '';

  final TextEditingController _searchCtrl = TextEditingController();

  AdminInspectionFilter get _filter {
    return AdminInspectionFilter(
      technicianId: _techFilter,
      locationId: _locFilter,
      status: _statusFilter,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _statusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'OK':
        return const Color(0xFF22C55E);
      case 'NOT_OK':
        return const Color(0xFFEF4444);
      case 'PARTIAL':
        return const Color(0xFFF59E0B);
      case 'NOT_REACHABLE':
        return const Color(0xFF94A3B8);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  Color _statusBg(String? status) {
    switch (status?.toUpperCase()) {
      case 'OK':
        return const Color(0xFFDCFCE7);
      case 'NOT_OK':
        return const Color(0xFFFEE2E2);
      case 'PARTIAL':
        return const Color(0xFFFEF9C3);
      case 'NOT_REACHABLE':
        return const Color(0xFFF1F5F9);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _statusTextColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'OK':
        return const Color(0xFF15803D);
      case 'NOT_OK':
        return const Color(0xFFB91C1C);
      case 'PARTIAL':
        return const Color(0xFFA16207);
      case 'NOT_REACHABLE':
        return const Color(0xFF475569);
      default:
        return const Color(0xFF475569);
    }
  }

  String _statusLabel(String? status, bool isAr) {
    if (isAr) {
      switch (status?.toUpperCase()) {
        case 'OK':
          return 'سليم';
        case 'NOT_OK':
          return 'غير سليم';
        case 'PARTIAL':
          return 'جزئي';
        case 'NOT_REACHABLE':
          return 'غير متاح';
        default:
          return 'الكل';
      }
    }

    switch (status?.toUpperCase()) {
      case 'OK':
        return 'OK';
      case 'NOT_OK':
        return 'Not OK';
      case 'PARTIAL':
        return 'Partial';
      case 'NOT_REACHABLE':
        return 'Unreachable';
      default:
        return 'All';
    }
  }

  Map<String, int> _buildStats(List<InspectionDetail> list) {
    final m = <String, int>{
      'total': list.length,
      'OK': 0,
      'NOT_OK': 0,
      'PARTIAL': 0,
      'NOT_REACHABLE': 0,
    };

    for (final item in list) {
      final s = item.inspectionStatus.toUpperCase();
      if (m.containsKey(s)) {
        m[s] = m[s]! + 1;
      }
    }

    return m;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final techs = ref.watch(techniciansProvider).valueOrNull ?? [];
    final locs = ref.watch(locationsProvider).valueOrNull ?? [];
    final inspectionsAsync = ref.watch(adminInspectionsProvider(_filter));

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: inspectionsAsync.when(
        loading: () => const _LoadingView(),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () {
            ref.invalidate(adminInspectionsProvider(_filter));
          },
        ),
        data: (inspections) {
          var filtered = [...inspections];

          if (_search.trim().isNotEmpty) {
            final q = _search.trim().toLowerCase();

            filtered = filtered.where((i) {
              return i.deviceName.toLowerCase().contains(q) ||
                  i.technicianName.toLowerCase().contains(q) ||
                  i.deviceCode.toLowerCase().contains(q) ||
                  i.locationText.toLowerCase().contains(q) ||
                  i.reportNumber.toLowerCase().contains(q) ||
                  (i.issueReason ?? '').toLowerCase().contains(q) ||
                  (i.notes ?? '').toLowerCase().contains(q);
            }).toList();
          }

          final stats = _buildStats(filtered);

          return NestedScrollView(
            headerSliverBuilder: (ctx, _) => [
              SliverAppBar(
                expandedHeight: 270,
                pinned: true,
                elevation: 0,
                backgroundColor: const Color(0xFF1a3a5c),
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    onPressed: () {
                      ref.invalidate(adminInspectionsProvider(_filter));
                      ref.invalidate(monthlyInspectionsProvider);
                      ref.invalidate(adminStatsProvider);
                      ref.invalidate(adminAnalyticsProvider);
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: _HeaderBackground(
                    stats: stats,
                    isAr: l.isAr,
                    statusColor: _statusColor,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(120),
                  child: _FiltersBar(
                    isAr: l.isAr,
                    searchCtrl: _searchCtrl,
                    techFilter: _techFilter,
                    locFilter: _locFilter,
                    statusFilter: _statusFilter,
                    techs: techs,
                    locs: locs,
                    statusLabel: (s) => _statusLabel(s, l.isAr),
                    statusColor: _statusColor,
                    onSearch: (v) => setState(() => _search = v),
                    onTech: (v) => setState(() => _techFilter = v),
                    onLoc: (v) => setState(() => _locFilter = v),
                    onStatus: (v) => setState(() => _statusFilter = v),
                  ),
                ),
              ),
            ],
            body: RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () async {
                ref.invalidate(adminInspectionsProvider(_filter));
                ref.invalidate(monthlyInspectionsProvider);
                ref.invalidate(adminStatsProvider);
                ref.invalidate(adminAnalyticsProvider);
              },
              child: filtered.isEmpty
                  ? _EmptyState(isAr: l.isAr)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final item = filtered[i];

                        return _InspectionTile(
                          inspection: item,
                          isAr: l.isAr,
                          statusColor: _statusColor,
                          statusBg: _statusBg,
                          statusText: _statusTextColor,
                          statusLabel: (s) => _statusLabel(s, l.isAr),
                          onTap: () {
                            showModalBottomSheet(
                              context: ctx,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => _InspectionDetailSheet(
                                inspection: item,
                                isAr: l.isAr,
                                statusColor: _statusColor,
                                statusBg: _statusBg,
                                statusText: _statusTextColor,
                                statusLabel: (s) => _statusLabel(s, l.isAr),
                              ),
                            );
                          },
                        )
                            .animate(
                              delay:
                                  Duration(milliseconds: math.min(i * 35, 400)),
                            )
                            .fadeIn(duration: 280.ms)
                            .slideY(
                              begin: 0.06,
                              end: 0,
                              duration: 280.ms,
                            );
                      },
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _HeaderBackground extends StatelessWidget {
  final Map<String, int> stats;
  final bool isAr;
  final Color Function(String?) statusColor;

  const _HeaderBackground({
    required this.stats,
    required this.isAr,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1a3a5c),
            Color(0xFF0f2540),
            Color(0xFF1a4a6c),
          ],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.assignment_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? 'التقارير الميدانية' : 'Field Reports',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              isAr
                                  ? 'متابعة جميع عمليات الفحص من الباك إند'
                                  : 'All backend inspections in one place',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _StatPill(
                        label: isAr ? 'الإجمالي' : 'Total',
                        value: stats['total'] ?? 0,
                        textColor: Colors.white,
                        bgColor: Colors.white.withOpacity(0.12),
                        borderColor: Colors.white.withOpacity(0.2),
                      ),
                      const SizedBox(width: 8),
                      _StatPill(
                        label: isAr ? 'سليم' : 'OK',
                        value: stats['OK'] ?? 0,
                        textColor: const Color(0xFF4ADE80),
                        bgColor: const Color(0xFF4ADE80).withOpacity(0.12),
                        borderColor: const Color(0xFF4ADE80).withOpacity(0.25),
                      ),
                      const SizedBox(width: 8),
                      _StatPill(
                        label: isAr ? 'غير سليم' : 'Not OK',
                        value: stats['NOT_OK'] ?? 0,
                        textColor: const Color(0xFFF87171),
                        bgColor: const Color(0xFFF87171).withOpacity(0.12),
                        borderColor: const Color(0xFFF87171).withOpacity(0.25),
                      ),
                      const SizedBox(width: 8),
                      _StatPill(
                        label: isAr ? 'جزئي' : 'Partial',
                        value: stats['PARTIAL'] ?? 0,
                        textColor: const Color(0xFFFBBF24),
                        bgColor: const Color(0xFFFBBF24).withOpacity(0.12),
                        borderColor: const Color(0xFFFBBF24).withOpacity(0.25),
                      ),
                    ],
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

class _StatPill extends StatelessWidget {
  final String label;
  final int value;
  final Color textColor;
  final Color bgColor;
  final Color borderColor;

  const _StatPill({
    required this.label,
    required this.value,
    required this.textColor,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                color: textColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  final bool isAr;
  final TextEditingController searchCtrl;
  final String? techFilter;
  final String? locFilter;
  final String? statusFilter;
  final List<TechnicianModel> techs;
  final List<LocationModel> locs;
  final String Function(String?) statusLabel;
  final Color Function(String?) statusColor;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onTech;
  final ValueChanged<String?> onLoc;
  final ValueChanged<String?> onStatus;

  const _FiltersBar({
    required this.isAr,
    required this.searchCtrl,
    required this.techFilter,
    required this.locFilter,
    required this.statusFilter,
    required this.techs,
    required this.locs,
    required this.statusLabel,
    required this.statusColor,
    required this.onSearch,
    required this.onTech,
    required this.onLoc,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    final techValue = techs.any((t) => t.id == techFilter) ? techFilter : null;
    final locValue = locs.any((l) => l.id == locFilter) ? locFilter : null;

    return Container(
      color: const Color(0xFF1a3a5c),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.13),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 0.5,
              ),
            ),
            child: TextField(
              controller: searchCtrl,
              onChanged: onSearch,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: isAr
                    ? 'بحث بالجهاز أو الفني أو الكود أو التقرير...'
                    : 'Search by device, technician, code or report...',
                hintStyle: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.45),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.white.withOpacity(0.5),
                  size: 18,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _GlassDropdown(
                  hint: isAr ? 'الفني' : 'Technician',
                  value: techValue,
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        isAr ? 'كل الفنيين' : 'All Technicians',
                        style: _dropStyle,
                      ),
                    ),
                    ...techs.map((t) {
                      return DropdownMenuItem<String?>(
                        value: t.id,
                        child: Text(
                          '${t.fullName} (${t.username})',
                          style: _dropStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: onTech,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _GlassDropdown(
                  hint: isAr ? 'الموقع' : 'Location',
                  value: locValue,
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        isAr ? 'كل المواقع' : 'All Locations',
                        style: _dropStyle,
                      ),
                    ),
                    ...locs.map((loc) {
                      return DropdownMenuItem<String?>(
                        value: loc.id,
                        child: Text(
                          loc.name,
                          style: _dropStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: onLoc,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <String?>[
                null,
                'OK',
                'NOT_OK',
                'PARTIAL',
                'NOT_REACHABLE',
              ].map((s) {
                return _StatusChip(
                  label: statusLabel(s),
                  statusKey: s,
                  selected: statusFilter == s,
                  activeColor: s == null ? Colors.white : statusColor(s),
                  onTap: () => onStatus(s),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static const _dropStyle = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 12,
    color: Color(0xFF1E293B),
  );
}

class _GlassDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<DropdownMenuItem<String?>> items;
  final ValueChanged<String?> onChanged;

  const _GlassDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
          width: 0.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: Colors.white.withOpacity(0.6),
          ),
          hint: Text(
            hint,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String? statusKey;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.statusKey,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? activeColor.withOpacity(0.18)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? activeColor : Colors.white.withOpacity(0.2),
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (statusKey != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        selected ? activeColor : Colors.white.withOpacity(0.4),
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color:
                      selected ? activeColor : Colors.white.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InspectionTile extends StatelessWidget {
  final InspectionDetail inspection;
  final bool isAr;
  final Color Function(String?) statusColor;
  final Color Function(String?) statusBg;
  final Color Function(String?) statusText;
  final String Function(String?) statusLabel;
  final VoidCallback onTap;

  const _InspectionTile({
    required this.inspection,
    required this.isAr,
    required this.statusColor,
    required this.statusBg,
    required this.statusText,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = statusColor(inspection.inspectionStatus);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.12),
                width: 0.5,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _TechAvatar(name: inspection.technicianName),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 12, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  inspection.deviceName,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _StatusBadge(
                                label: statusLabel(inspection.inspectionStatus),
                                bgColor: statusBg(inspection.inspectionStatus),
                                textColor:
                                    statusText(inspection.inspectionStatus),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            inspection.deviceCode,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline_rounded,
                                size: 12,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  inspection.technicianName,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (inspection.locationText.trim().isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    inspection.locationText,
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 4),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TechAvatar extends StatelessWidget {
  final String name;

  const _TechAvatar({required this.name});

  String get _initials {
    final clean = name.trim();
    if (clean.isEmpty) return '?';

    final parts = clean.split(' ');

    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}';
    }

    return clean[0];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a3a5c), Color(0xFF1e6aa0)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _StatusBadge({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _InspectionDetailSheet extends StatelessWidget {
  final InspectionDetail inspection;
  final bool isAr;
  final Color Function(String?) statusColor;
  final Color Function(String?) statusBg;
  final Color Function(String?) statusText;
  final String Function(String?) statusLabel;

  const _InspectionDetailSheet({
    required this.inspection,
    required this.isAr,
    required this.statusColor,
    required this.statusBg,
    required this.statusText,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = statusColor(inspection.inspectionStatus);

    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 48,
                    margin: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inspection.deviceName,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          inspection.reportNumber,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(
                    label: statusLabel(inspection.inspectionStatus),
                    bgColor: statusBg(inspection.inspectionStatus),
                    textColor: statusText(inspection.inspectionStatus),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 0.5),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                children: [
                  _DetailSection(
                    title: isAr ? 'معلومات الجهاز' : 'Device Info',
                    icon: Icons.devices_outlined,
                    rows: [
                      _FieldRow(
                        label: isAr ? 'اسم الجهاز' : 'Device Name',
                        value: inspection.deviceName,
                      ),
                      _FieldRow(
                        label: isAr ? 'كود الجهاز' : 'Device Code',
                        value: inspection.deviceCode,
                      ),
                      _FieldRow(
                        label: isAr ? 'الموقع' : 'Location',
                        value: inspection.locationText,
                      ),
                      _FieldRow(
                        label: isAr ? 'الحالة' : 'Status',
                        value: statusLabel(inspection.inspectionStatus),
                        valueColor: color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DetailSection(
                    title: isAr ? 'معلومات الفني' : 'Technician Info',
                    icon: Icons.person_outline_rounded,
                    rows: [
                      _FieldRow(
                        label: isAr ? 'اسم الفني' : 'Technician Name',
                        value: inspection.technicianName,
                      ),
                      _FieldRow(
                        label: isAr ? 'التاريخ' : 'Date',
                        value:
                            '${inspection.inspectedAt.day}/${inspection.inspectedAt.month}/${inspection.inspectedAt.year}',
                      ),
                      _FieldRow(
                        label: isAr ? 'الوقت' : 'Time',
                        value:
                            '${inspection.inspectedAt.hour.toString().padLeft(2, '0')}:${inspection.inspectedAt.minute.toString().padLeft(2, '0')}',
                      ),
                      _FieldRow(
                        label: 'GPS',
                        value:
                            '${inspection.latitude.toStringAsFixed(4)}, ${inspection.longitude.toStringAsFixed(4)}',
                      ),
                    ],
                  ),
                  if (inspection.notes?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    _NoteBox(
                      title: isAr ? 'ملاحظات' : 'Notes',
                      text: inspection.notes!,
                      color: const Color(0xFF1a3a5c),
                    ),
                  ],
                  if (inspection.issueReason?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    _NoteBox(
                      title: isAr ? 'سبب المشكلة' : 'Issue Reason',
                      text: inspection.issueReason!,
                      color: const Color(0xFFEF4444),
                    ),
                  ],
                  if (inspection.imageUrl != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        inspection.imageUrl!,
                        height: 210,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            height: 130,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported_rounded,
                                color: Color(0xFF94A3B8),
                                size: 38,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: Text(
                        isAr ? 'إغلاق' : 'Close',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
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

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_FieldRow> rows;

  const _DetailSection({
    required this.title,
    required this.icon,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(icon, size: 14, color: const Color(0xFF1a3a5c)),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1a3a5c),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, indent: 14, endIndent: 14),
          ...rows,
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _FieldRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value.trim().isEmpty ? '-' : value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              safeValue,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  final String title;
  final String text;
  final Color color;

  const _NoteBox({
    required this.title,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: Color(0xFF1E293B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: Column(
        children: [
          Container(
            height: 270,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1a3a5c), Color(0xFF0f2540)],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              itemBuilder: (_, i) => _ShimmerCard()
                  .animate(delay: Duration(milliseconds: i * 80))
                  .fadeIn(duration: 400.ms),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    width: double.infinity,
                    height: 11,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 140,
                    height: 9,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 1200.ms, color: Colors.grey.shade100);
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
    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: Color(0xFFEF4444),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'حدث خطأ',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'حاول مجدداً',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
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
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.18),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  color: Color(0xFF94A3B8),
                  size: 48,
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(height: 16),
              Text(
                isAr ? 'لا توجد نتائج' : 'No results found',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isAr
                    ? 'جربي تغيير الفلاتر أو البحث بكلمة مختلفة'
                    : 'Try adjusting your filters or search term',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: Color(0xFFB0BEC5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}