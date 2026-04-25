import 'package:access_track/admin/admin_models.dart';
import 'package:access_track/admin/admin_providers.dart';
import 'package:access_track/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ══════════════════════════════════════════════════════════
//  LOCAL FILTER MODEL
// ══════════════════════════════════════════════════════════
class _LocationFilter {
  final String search;
  final String cluster;
  final String building;
  final String zone;
  final String type;
  final String direction; // IN | OUT | ALL
  final int? laneMin;
  final int? laneMax;
  final int? devicesMin;
  final int? devicesMax;
  final bool faultyOnly;

  const _LocationFilter({
    this.search = '',
    this.cluster = 'ALL',
    this.building = 'ALL',
    this.zone = 'ALL',
    this.type = 'ALL',
    this.direction = 'ALL',
    this.laneMin,
    this.laneMax,
    this.devicesMin,
    this.devicesMax,
    this.faultyOnly = false,
  });

  _LocationFilter copyWith({
    String? search,
    String? cluster,
    String? building,
    String? zone,
    String? type,
    String? direction,
    int? laneMin,
    int? laneMax,
    int? devicesMin,
    int? devicesMax,
    bool? faultyOnly,
    bool clearLaneMin = false,
    bool clearLaneMax = false,
    bool clearDevicesMin = false,
    bool clearDevicesMax = false,
  }) =>
      _LocationFilter(
        search: search ?? this.search,
        cluster: cluster ?? this.cluster,
        building: building ?? this.building,
        zone: zone ?? this.zone,
        type: type ?? this.type,
        direction: direction ?? this.direction,
        laneMin: clearLaneMin ? null : (laneMin ?? this.laneMin),
        laneMax: clearLaneMax ? null : (laneMax ?? this.laneMax),
        devicesMin: clearDevicesMin ? null : (devicesMin ?? this.devicesMin),
        devicesMax: clearDevicesMax ? null : (devicesMax ?? this.devicesMax),
        faultyOnly: faultyOnly ?? this.faultyOnly,
      );

  int get activeCount {
    int c = 0;
    if (cluster != 'ALL') c++;
    if (building != 'ALL') c++;
    if (zone != 'ALL') c++;
    if (type != 'ALL') c++;
    if (direction != 'ALL') c++;
    if (laneMin != null || laneMax != null) c++;
    if (devicesMin != null || devicesMax != null) c++;
    if (faultyOnly) c++;
    return c;
  }

  bool get isEmpty => activeCount == 0 && search.isEmpty;

  _LocationFilter get reset => const _LocationFilter();
}

// ══════════════════════════════════════════════════════════
//  MAIN SCREEN
// ══════════════════════════════════════════════════════════
class AdminLocationScreen extends ConsumerStatefulWidget {
  const AdminLocationScreen({super.key});

  @override
  ConsumerState<AdminLocationScreen> createState() =>
      _AdminLocationScreenState();
}

class _AdminLocationScreenState extends ConsumerState<AdminLocationScreen>
    with SingleTickerProviderStateMixin {
  _LocationFilter _filter = const _LocationFilter();
  final _searchCtrl = TextEditingController();
  late final AnimationController _headerAnim;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _searchCtrl.addListener(
        () => setState(() => _filter = _filter.copyWith(search: _searchCtrl.text)));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _headerAnim.dispose();
    super.dispose();
  }

  List<LocationModel> _applyFilter(List<LocationModel> all) {
    return all.where((loc) {
      final q = _filter.search.toLowerCase();
      if (q.isNotEmpty) {
        final haystack =
            '${loc.name} ${loc.cluster ?? ''} ${loc.building ?? ''} ${loc.zone ?? ''}'
                .toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      if (_filter.cluster != 'ALL' &&
          loc.cluster != _filter.cluster) return false;
      if (_filter.building != 'ALL' &&
          loc.building != _filter.building) return false;
      if (_filter.zone != 'ALL' && loc.zone != _filter.zone) return false;
      // Removed type, direction, lane filters because LocationModel does not have these fields
      if (_filter.devicesMin != null &&
          loc.deviceCount < _filter.devicesMin!) return false;
      if (_filter.devicesMax != null &&
          loc.deviceCount > _filter.devicesMax!) return false;
      if (_filter.faultyOnly && loc.faultyDeviceCount == 0) return false;
      return true;
    }).toList();
  }

  void _openFilterSheet(List<LocationModel> all) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationFilterSheet(
        locations: all,
        current: _filter,
        onApply: (f) => setState(() => _filter = f),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locationsAsync = ref.watch(locationsProvider);
    final globalFilter = ref.watch(adminGlobalFilterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: locationsAsync.when(
        loading: () => const _LoadingScaffold(),
        error: (e, _) => _ErrorScaffold(error: e.toString()),
        data: (locations) {
          // Apply global filter first
          var afterGlobal = locations;
          if (globalFilter.cluster != 'ALL') {
            afterGlobal = afterGlobal
                .where((loc) =>
                    (loc.cluster?.contains(globalFilter.cluster) ?? false) ||
                    loc.name.contains(globalFilter.cluster))
                .toList();
          }
          if (globalFilter.building != 'ALL') {
            afterGlobal = afterGlobal
                .where((loc) => loc.building == globalFilter.building)
                .toList();
          }
          // Apply local filter
          final filtered = _applyFilter(afterGlobal);

          // Unique values for filter options
          final allClusters = locations
              .map((l) => l.cluster)
              .whereType<String>()
              .toSet()
              .toList()
            ..sort();
          final allBuildings = locations
              .map((l) => l.building)
              .whereType<String>()
              .toSet()
              .toList()
            ..sort();
          final allZones = locations
              .map((l) => l.zone)
              .whereType<String>()
              .toSet()
              .toList()
            ..sort();
          // Removed allTypes: LocationModel has no 'type' property

          // Summary stats
          final totalDevices =
              filtered.fold(0, (sum, l) => sum + l.deviceCount);
          final faultyLocs =
              filtered.where((l) => l.faultyDeviceCount > 0).length;

          return CustomScrollView(
            slivers: [
              // ── Gradient App Bar ────────────────────────────────
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                floating: false,
                elevation: 0,
                backgroundColor: const Color(0xFF0D47A1),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.maybePop(context),
                ),
                actions: [
                  _HeaderAction(
                    label: l.isAr ? 'EN' : 'عربي',
                    isText: true,
                    onTap: () => LanguageController.of(context).toggleLanguage(),
                  ),
                  _HeaderAction(
                    icon: Icons.filter_alt_rounded,
                    badge: _filter.activeCount,
                    onTap: () => _openFilterSheet(locations),
                    highlight: _filter.activeCount > 0,
                  ),
                  _HeaderAction(
                    icon: Icons.refresh_rounded,
                    onTap: () => ref.invalidate(locationsProvider),
                  ),
                  const SizedBox(width: 4),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: _AppBarBackground(
                    title: l.isAr ? 'إدارة المواقع' : 'Location Hub',
                    subtitle: l.isAr
                        ? 'التتبع والإدارة المكانية'
                        : 'Spatial tracking & management',
                    totalLocs: afterGlobal.length,
                    filteredLocs: filtered.length,
                    totalDevices: totalDevices,
                    faultyLocs: faultyLocs,
                    isAr: l.isAr,
                  ),
                ),
              ),

              // ── Search + Filter chips ────────────────────────────
              SliverToBoxAdapter(
                child: _SearchBar(
                  controller: _searchCtrl,
                  isAr: l.isAr,
                  filterCount: _filter.activeCount,
                  onFilterTap: () => _openFilterSheet(locations),
                  onClear: () {
                    _searchCtrl.clear();
                    setState(() => _filter = _filter.reset);
                  },
                ),
              ),

              // ── Active filter chips row ─────────────────────────
              if (!_filter.isEmpty)
                SliverToBoxAdapter(
                  child: _ActiveFilterChips(
                    filter: _filter,
                    isAr: l.isAr,
                    onRemove: (updated) => setState(() => _filter = updated),
                    onClearAll: () => setState(() => _filter = _filter.reset),
                  ),
                ),

              // ── Results header ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D47A1).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l.isAr
                              ? '${filtered.length} موقع'
                              : '${filtered.length} locations',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D47A1),
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!_filter.isEmpty)
                        Text(
                          l.isAr
                              ? 'من أصل ${afterGlobal.length}'
                              : 'of ${afterGlobal.length} total',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontFamily: 'Cairo'),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Location Cards ───────────────────────────────────
              filtered.isEmpty
                  ? SliverFillRemaining(
                      child: _EmptyState(isAr: l.isAr),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) => _LocationCard(
                          location: filtered[i],
                          isAr: l.isAr,
                          index: i,
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  APP BAR BACKGROUND
// ══════════════════════════════════════════════════════════
class _AppBarBackground extends StatelessWidget {
  final String title;
  final String subtitle;
  final int totalLocs;
  final int filteredLocs;
  final int totalDevices;
  final int faultyLocs;
  final bool isAr;

  const _AppBarBackground({
    required this.title,
    required this.subtitle,
    required this.totalLocs,
    required this.filteredLocs,
    required this.totalDevices,
    required this.faultyLocs,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A2472), Color(0xFF0D47A1), Color(0xFF1565C0)],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -40,
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
            left: -20,
            bottom: 20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 56, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.location_city_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Cairo',
                                  letterSpacing: -0.3)),
                          Text(subtitle,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 12,
                                  fontFamily: 'Cairo')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Stat pills
                  Row(
                    children: [
                      _StatPill(
                          value: totalLocs.toString(),
                          label: isAr ? 'مواقع' : 'Locations',
                          icon: Icons.place_rounded),
                      const SizedBox(width: 8),
                      _StatPill(
                          value: totalDevices.toString(),
                          label: isAr ? 'جهاز' : 'Devices',
                          icon: Icons.devices_rounded),
                      const SizedBox(width: 8),
                      if (faultyLocs > 0)
                        _StatPill(
                            value: faultyLocs.toString(),
                            label: isAr ? 'مشكلة' : 'Issues',
                            icon: Icons.warning_amber_rounded,
                            isAlert: true),
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
  final String value;
  final String label;
  final IconData icon;
  final bool isAlert;

  const _StatPill({
    required this.value,
    required this.label,
    required this.icon,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isAlert
            ? Colors.orange.withOpacity(0.25)
            : Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isAlert
              ? Colors.orange.withOpacity(0.5)
              : Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: isAlert ? Colors.orange.shade200 : Colors.white70),
          const SizedBox(width: 6),
          Text('$value $label',
              style: TextStyle(
                  color:
                      isAlert ? Colors.orange.shade100 : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo')),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final bool isText;
  final int badge;
  final bool highlight;
  final VoidCallback onTap;

  const _HeaderAction({
    this.icon,
    this.label,
    this.isText = false,
    this.badge = 0,
    this.highlight = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: highlight
                ? Colors.amber.withOpacity(0.85)
                : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: isText
                    ? Text(label!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            fontFamily: 'Cairo'))
                    : Icon(icon, color: Colors.white, size: 20),
              ),
            ),
          ),
          if (badge > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(badge.toString(),
                      style: const TextStyle(
                          color: Color(0xFF0D47A1),
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  SEARCH BAR
// ══════════════════════════════════════════════════════════
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isAr;
  final int filterCount;
  final VoidCallback onFilterTap;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.isAr,
    required this.filterCount,
    required this.onFilterTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDDE5FF)),
              ),
              child: TextField(
                controller: controller,
                style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Cairo',
                    color: Color(0xFF1A237E)),
                decoration: InputDecoration(
                  hintText: isAr
                      ? 'بحث بالاسم، الكلاستر، المبنى...'
                      : 'Search name, cluster, building...',
                  hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                      fontFamily: 'Cairo'),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFF0D47A1), size: 20),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon:
                              const Icon(Icons.close_rounded, size: 18),
                          onPressed: controller.clear,
                          color: Colors.grey.shade400,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Filter button
          GestureDetector(
            onTap: onFilterTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: filterCount > 0
                    ? const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                      ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (filterCount > 0
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF0D47A1))
                        .withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded,
                      color: Colors.white, size: 18),
                  if (filterCount > 0) ...[
                    const SizedBox(width: 6),
                    Text(filterCount.toString(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  ACTIVE FILTER CHIPS
// ══════════════════════════════════════════════════════════
class _ActiveFilterChips extends StatelessWidget {
  final _LocationFilter filter;
  final bool isAr;
  final ValueChanged<_LocationFilter> onRemove;
  final VoidCallback onClearAll;

  const _ActiveFilterChips({
    required this.filter,
    required this.isAr,
    required this.onRemove,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <_FilterChipData>[];

    if (filter.cluster != 'ALL') {
      chips.add(_FilterChipData(
          label: filter.cluster,
          onRemove: () =>
              onRemove(filter.copyWith(cluster: 'ALL'))));
    }
    if (filter.building != 'ALL') {
      chips.add(_FilterChipData(
          label: filter.building,
          onRemove: () =>
              onRemove(filter.copyWith(building: 'ALL'))));
    }
    if (filter.zone != 'ALL') {
      chips.add(_FilterChipData(
          label: filter.zone,
          onRemove: () => onRemove(filter.copyWith(zone: 'ALL'))));
    }
    if (filter.type != 'ALL') {
      chips.add(_FilterChipData(
          label: filter.type,
          onRemove: () => onRemove(filter.copyWith(type: 'ALL'))));
    }
    if (filter.direction != 'ALL') {
      chips.add(_FilterChipData(
          label: filter.direction,
          color: filter.direction == 'IN'
              ? const Color(0xFF1565C0)
              : const Color(0xFFAD1457),
          onRemove: () =>
              onRemove(filter.copyWith(direction: 'ALL'))));
    }
    if (filter.laneMin != null || filter.laneMax != null) {
      final label =
          'Lane: ${filter.laneMin ?? 0} – ${filter.laneMax ?? '∞'}';
      chips.add(_FilterChipData(
          label: label,
          onRemove: () => onRemove(filter.copyWith(
              clearLaneMin: true, clearLaneMax: true))));
    }
    if (filter.devicesMin != null || filter.devicesMax != null) {
      final label =
          'Devices: ${filter.devicesMin ?? 0} – ${filter.devicesMax ?? '∞'}';
      chips.add(_FilterChipData(
          label: label,
          onRemove: () => onRemove(filter.copyWith(
              clearDevicesMin: true, clearDevicesMax: true))));
    }
    if (filter.faultyOnly) {
      chips.add(_FilterChipData(
          label: isAr ? 'معطل فقط' : 'Faulty only',
          color: Colors.red.shade700,
          onRemove: () =>
              onRemove(filter.copyWith(faultyOnly: false))));
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...chips.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _Chip(data: c),
                )),
            // Clear all
            GestureDetector(
              onTap: onClearAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.clear_all_rounded,
                        size: 14, color: Colors.red.shade600),
                    const SizedBox(width: 4),
                    Text(isAr ? 'مسح الكل' : 'Clear all',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Cairo')),
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

class _FilterChipData {
  final String label;
  final Color color;
  final VoidCallback onRemove;

  const _FilterChipData({
    required this.label,
    this.color = const Color(0xFF0D47A1),
    required this.onRemove,
  });
}

class _Chip extends StatelessWidget {
  final _FilterChipData data;
  const _Chip({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: data.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(data.label,
              style: TextStyle(
                  fontSize: 12,
                  color: data.color,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo')),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: data.onRemove,
            child: Icon(Icons.close_rounded, size: 14, color: data.color),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  LOCATION CARD  (premium redesign)
// ══════════════════════════════════════════════════════════
class _LocationCard extends StatelessWidget {
  final LocationModel location;
  final bool isAr;
  final int index;

  const _LocationCard({
    required this.location,
    required this.isAr,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final hasIssues = location.faultyDeviceCount > 0;
    final hasNoDevices = location.deviceCount == 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasIssues
              ? Colors.orange.withOpacity(0.4)
              : const Color(0xFFE8EDFF),
          width: hasIssues ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: hasIssues
                ? Colors.orange.withOpacity(0.08)
                : const Color(0xFF0D47A1).withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // ── Top accent bar ────────────────────────────
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasIssues
                      ? [Colors.orange.shade400, Colors.red.shade300]
                      : [
                          const Color(0xFF0D47A1),
                          const Color(0xFF42A5F5),
                        ],
                ),
              ),
            ),
            // ── Card body ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      // Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: hasIssues
                                ? [
                                    Colors.orange.shade100,
                                    Colors.red.shade50
                                  ]
                                : [
                                    const Color(0xFFE8EDFF),
                                    const Color(0xFFD0DBFF),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          hasIssues
                              ? Icons.warning_rounded
                              : Icons.apartment_rounded,
                          color: hasIssues
                              ? Colors.orange.shade700
                              : const Color(0xFF0D47A1),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              location.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0D1B5E),
                                fontFamily: 'Cairo',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Device count badges
                            Wrap(
                              spacing: 6,
                              children: [
                                _MiniTag(
                                  icon: Icons.devices_rounded,
                                  label:
                                      '${location.deviceCount} ${isAr ? "جهاز" : "Devices"}',
                                  color: hasNoDevices
                                      ? Colors.grey.shade400
                                      : const Color(0xFF0D47A1),
                                ),
                                if (hasIssues)
                                  _MiniTag(
                                    icon: Icons.error_outline_rounded,
                                    label:
                                        '${location.faultyDeviceCount} ${isAr ? "معطل" : "Faulty"}',
                                    color: Colors.red.shade600,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ── Info tags grid ──────────────────────
                  if (location.cluster != null ||
                      location.building != null ||
                      location.zone != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (location.cluster?.isNotEmpty == true)
                            _InfoPill(
                              icon: Icons.hub_rounded,
                              label: location.cluster!,
                              color: const Color(0xFF4527A0),
                            ),
                          if (location.building?.isNotEmpty == true)
                            _InfoPill(
                              icon: Icons.business_rounded,
                              label: location.building!,
                              color: const Color(0xFF1565C0),
                              isRtl: true,
                            ),
                          if (location.zone?.isNotEmpty == true)
                            _InfoPill(
                              icon: Icons.map_rounded,
                              label: location.zone!,
                              color: const Color(0xFF00695C),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 80 + index * 40))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.06, curve: Curves.easeOut);
  }
}

class _MiniTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: 'Cairo')),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isRtl;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
    this.isRtl = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color.withOpacity(0.8)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              textDirection:
                  isRtl ? TextDirection.rtl : TextDirection.ltr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                fontFamily: 'Cairo',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  FILTER BOTTOM SHEET  (powerful — all columns)
// ══════════════════════════════════════════════════════════
class _LocationFilterSheet extends StatefulWidget {
  final List<LocationModel> locations;
  final _LocationFilter current;
  final ValueChanged<_LocationFilter> onApply;

  const _LocationFilterSheet({
    required this.locations,
    required this.current,
    required this.onApply,
  });

  @override
  State<_LocationFilterSheet> createState() => _LocationFilterSheetState();
}

class _LocationFilterSheetState extends State<_LocationFilterSheet> {
  late _LocationFilter _local;

  final _laneMinCtrl = TextEditingController();
  final _laneMaxCtrl = TextEditingController();
  final _devMinCtrl = TextEditingController();
  final _devMaxCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _local = widget.current;
    _laneMinCtrl.text = _local.laneMin?.toString() ?? '';
    _laneMaxCtrl.text = _local.laneMax?.toString() ?? '';
    _devMinCtrl.text = _local.devicesMin?.toString() ?? '';
    _devMaxCtrl.text = _local.devicesMax?.toString() ?? '';
  }

  @override
  void dispose() {
    _laneMinCtrl.dispose();
    _laneMaxCtrl.dispose();
    _devMinCtrl.dispose();
    _devMaxCtrl.dispose();
    super.dispose();
  }

  List<String> _unique(String Function(LocationModel) f) =>
      widget.locations.map(f).where((s) => s.isNotEmpty).toSet().toList()
        ..sort();

  void _apply() {
    final updated = _local.copyWith(
      laneMin: _laneMinCtrl.text.isNotEmpty
          ? int.tryParse(_laneMinCtrl.text)
          : null,
      laneMax: _laneMaxCtrl.text.isNotEmpty
          ? int.tryParse(_laneMaxCtrl.text)
          : null,
      devicesMin: _devMinCtrl.text.isNotEmpty
          ? int.tryParse(_devMinCtrl.text)
          : null,
      devicesMax: _devMaxCtrl.text.isNotEmpty
          ? int.tryParse(_devMaxCtrl.text)
          : null,
      clearLaneMin: _laneMinCtrl.text.isEmpty,
      clearLaneMax: _laneMaxCtrl.text.isEmpty,
      clearDevicesMin: _devMinCtrl.text.isEmpty,
      clearDevicesMax: _devMaxCtrl.text.isEmpty,
    );
    widget.onApply(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final clusters =
        _unique((loc) => loc.cluster ?? '');
    final buildings =
        _unique((loc) => loc.building ?? '');
    final zones = _unique((loc) => loc.zone ?? '');

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF0F4FF),
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // ── Sheet handle + header ─────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A2472), Color(0xFF1565C0)],
                ),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tune_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.isAr
                                  ? 'فلتر متقدم'
                                  : 'Advanced Filters',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Cairo'),
                            ),
                            Text(
                              l.isAr
                                  ? 'فلترة بكل الحقول'
                                  : 'Filter by every field',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 12,
                                  fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Active count badge
                        if (_local.activeCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade400,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_local.activeCount} ${l.isAr ? "فعّال" : "active"}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ───────────────────────────
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                children: [
                  // Cluster
                  _FilterSection(
                    title: l.isAr ? 'الكلاستر' : 'Cluster',
                    icon: Icons.hub_rounded,
                    child: _DropdownFilter(
                      value: _local.cluster,
                      allLabel:
                          l.isAr ? 'كل الكلاسترات' : 'All Clusters',
                      items: clusters,
                      onChanged: (v) =>
                          setState(() => _local = _local.copyWith(cluster: v)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Building
                  _FilterSection(
                    title: l.isAr ? 'المبنى' : 'Building',
                    icon: Icons.business_rounded,
                    child: _DropdownFilter(
                      value: _local.building,
                      allLabel: l.isAr ? 'كل المباني' : 'All Buildings',
                      items: buildings,
                      onChanged: (v) => setState(
                          () => _local = _local.copyWith(building: v)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Zone
                  _FilterSection(
                    title: l.isAr ? 'المنطقة' : 'Zone',
                    icon: Icons.map_rounded,
                    child: _DropdownFilter(
                      value: _local.zone,
                      allLabel: l.isAr ? 'كل المناطق' : 'All Zones',
                      items: zones,
                      onChanged: (v) =>
                          setState(() => _local = _local.copyWith(zone: v)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Devices count range
                  _FilterSection(
                    title: l.isAr ? 'عدد الأجهزة' : 'Devices Count',
                    icon: Icons.devices_rounded,
                    child: _RangeInputRow(
                      minCtrl: _devMinCtrl,
                      maxCtrl: _devMaxCtrl,
                      minHint: l.isAr ? 'من' : 'Min',
                      maxHint: l.isAr ? 'إلى' : 'Max',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Faulty only toggle
                  _FilterSection(
                    title: l.isAr ? 'الحالة' : 'Status',
                    icon: Icons.health_and_safety_rounded,
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _local = _local.copyWith(faultyOnly: !_local.faultyOnly)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _local.faultyOnly
                              ? Colors.red.shade50
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _local.faultyOnly
                                ? Colors.red.shade300
                                : const Color(0xFFDDE5FF),
                            width: _local.faultyOnly ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: _local.faultyOnly
                                  ? Colors.red.shade600
                                  : Colors.grey.shade400,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.isAr
                                        ? 'المواقع بها أجهزة معطلة فقط'
                                        : 'Only locations with faulty devices',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _local.faultyOnly
                                          ? Colors.red.shade700
                                          : const Color(0xFF0D1B5E),
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _local.faultyOnly,
                              onChanged: (v) => setState(
                                  () => _local = _local.copyWith(faultyOnly: v)),
                              activeColor: Colors.red.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),

            // ── Bottom action buttons ─────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 12,
                      offset: Offset(0, -4)),
                ],
              ),
              child: Row(
                children: [
                  // Reset
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _local = const _LocationFilter();
                          _laneMinCtrl.clear();
                          _laneMaxCtrl.clear();
                          _devMinCtrl.clear();
                          _devMaxCtrl.clear();
                        });
                      },
                      icon: const Icon(Icons.restart_alt_rounded, size: 18),
                      label: Text(l.isAr ? 'إعادة ضبط' : 'Reset',
                          style: const TextStyle(fontFamily: 'Cairo')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0D47A1),
                        side:
                            const BorderSide(color: Color(0xFFB0BEE8)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Apply
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _apply,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        l.isAr
                            ? 'تطبيق الفلتر'
                            : 'Apply Filters',
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w700,
                            fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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

// ── Filter building blocks ────────────────────────────────
class _FilterSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _FilterSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: const Color(0xFF0D47A1)),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D1B5E),
                fontFamily: 'Cairo',
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  final String value;
  final String allLabel;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _DropdownFilter({
    required this.value,
    required this.allLabel,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value != 'ALL'
              ? const Color(0xFF0D47A1).withOpacity(0.4)
              : const Color(0xFFDDE5FF),
          width: value != 'ALL' ? 1.5 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: value != 'ALL'
                ? const Color(0xFF0D47A1)
                : Colors.grey.shade400,
          ),
          items: [
            DropdownMenuItem(
              value: 'ALL',
              child: Text(allLabel,
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontFamily: 'Cairo',
                      fontSize: 13)),
            ),
            ...items.map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Color(0xFF0D1B5E),
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _RangeInputRow extends StatelessWidget {
  final TextEditingController minCtrl;
  final TextEditingController maxCtrl;
  final String minHint;
  final String maxHint;

  const _RangeInputRow({
    required this.minCtrl,
    required this.maxCtrl,
    required this.minHint,
    required this.maxHint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _NumField(ctrl: minCtrl, hint: minHint)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('–',
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w300)),
        ),
        Expanded(child: _NumField(ctrl: maxCtrl, hint: maxHint)),
      ],
    );
  }
}

class _NumField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;

  const _NumField({required this.ctrl, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE5FF)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0D1B5E),
            fontFamily: 'Cairo'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: Colors.grey.shade400, fontSize: 13),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  LOADING / ERROR STATES
// ══════════════════════════════════════════════════════════
class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();
  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF0D47A1)),
      );
}

class _ErrorScaffold extends StatelessWidget {
  final String error;
  const _ErrorScaffold({required this.error});
  @override
  Widget build(BuildContext context) => Center(
        child: Text(error,
            style: const TextStyle(color: Colors.red, fontFamily: 'Cairo')),
      );
}

class _EmptyState extends StatelessWidget {
  final bool isAr;
  const _EmptyState({required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EDFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded,
                size: 40, color: Color(0xFF0D47A1)),
          ),
          const SizedBox(height: 16),
          Text(
            isAr ? 'لا توجد مواقع مطابقة' : 'No locations found',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D1B5E),
                fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 6),
          Text(
            isAr
                ? 'جرّب تعديل الفلاتر أو البحث'
                : 'Try adjusting filters or search',
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontFamily: 'Cairo'),
          ),
        ],
      ),
    );
  }
}