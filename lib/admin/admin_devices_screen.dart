import 'package:access_track/admin/admin_models.dart';
import 'package:access_track/admin/admin_providers.dart';
import 'package:access_track/admin/admin_tasks_screen.dart';
import 'package:access_track/admin/admin_widgets.dart';
import 'package:access_track/admin/admin_filter_sheet.dart';
import 'package:access_track/app_constants.dart';
import 'package:access_track/app_localizations.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:access_track/core/widgets/widgets.dart'
    hide SectionHeader, ResponsiveStatGrid, StatCard;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_shared.dart';

class _DeviceFilter {
  final String search;
  final String status;
  final String building;
  final String type;
  final String location;
  final bool hasRecentInspection;

  const _DeviceFilter({
    this.search = '',
    this.status = 'ALL',
    this.building = 'ALL',
    this.type = 'ALL',
    this.location = 'ALL',
    this.hasRecentInspection = false,
  });

  _DeviceFilter copyWith({
    String? search,
    String? status,
    String? building,
    String? type,
    String? location,
    bool? hasRecentInspection,
  }) =>
      _DeviceFilter(
        search: search ?? this.search,
        status: status ?? this.status,
        building: building ?? this.building,
        type: type ?? this.type,
        location: location ?? this.location,
        hasRecentInspection:
            hasRecentInspection ?? this.hasRecentInspection,
      );

  int get activeCount {
    int c = 0;
    if (status != 'ALL') c++;
    if (building != 'ALL') c++;
    if (type != 'ALL') c++;
    if (location != 'ALL') c++;
    if (hasRecentInspection) c++;
    return c;
  }

  bool get isEmpty => activeCount == 0 && search.isEmpty;

  _DeviceFilter get reset => const _DeviceFilter();
}

DeviceStatus _deviceStatusFromKey(String value) {
  switch (value.trim().toLowerCase()) {
    case 'faulty':
    case 'out_of_service':
      return DeviceStatus.faulty;
    case 'maintenance':
    case 'needs_maintenance':
    case 'under_maintenance':
      return DeviceStatus.maintenance;
    case 'review':
    case 'under_review':
      return DeviceStatus.underReview;
    case 'good':
    case 'ok':
    default:
      return DeviceStatus.good;
  }
}

class AdminDevicesScreen extends ConsumerStatefulWidget {
  final String? initialFilter;
  final bool isViewer;

  const AdminDevicesScreen({
    super.key,
    this.initialFilter,
    this.isViewer = false,
  });

  @override
  ConsumerState<AdminDevicesScreen> createState() =>
      _AdminDevicesScreenState();
}

class _AdminDevicesScreenState extends ConsumerState<AdminDevicesScreen> {
  late _DeviceFilter _filter;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = _DeviceFilter(
      status: widget.initialFilter ?? 'ALL',
    );
    _searchCtrl.addListener(
      () => setState(
        () => _filter = _filter.copyWith(search: _searchCtrl.text),
      ),
    );

    if (widget.initialFilter != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(adminGlobalFilterProvider.notifier).state = ref
            .read(adminGlobalFilterProvider)
            .copyWith(deviceStatus: widget.initialFilter);
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AdminDeviceModel> _applyFilter(List<AdminDeviceModel> all) {
    return all.where((d) {
      final q = _filter.search.toLowerCase();
      if (q.isNotEmpty) {
        final hay =
            '${d.name} ${d.deviceCode} ${d.locationName ?? ''} ${d.typeName ?? ''}'
                .toLowerCase();
        if (!hay.contains(q)) return false;
      }

      final status = _deviceStatusFromKey(d.statusKey);

      if (_filter.status != 'ALL') {
        if (_filter.status == 'OK' && status != DeviceStatus.good) {
          return false;
        }
        if (_filter.status == 'FAULTY' && status != DeviceStatus.faulty) {
          return false;
        }
        if (_filter.status == 'MAINTENANCE' &&
            status != DeviceStatus.maintenance) {
          return false;
        }
        if (_filter.status == 'OFFLINE' &&
            status != DeviceStatus.underReview) {
          return false;
        }
      }

      if (_filter.building != 'ALL' &&
          d.locationBuilding != _filter.building) {
        return false;
      }

      if (_filter.type != 'ALL' && d.typeName != _filter.type) {
        return false;
      }

      if (_filter.location != 'ALL' &&
          d.locationName != _filter.location) {
        return false;
      }

      if (_filter.hasRecentInspection) {
        if (d.lastInspectionAt == null) return false;
        final diff = DateTime.now().difference(d.lastInspectionAt!).inDays;
        if (diff > 30) return false;
      }

      return true;
    }).toList();
  }

  void _openFilter(List<AdminDeviceModel> all) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeviceFilterSheet(
        devices: all,
        current: _filter,
        onApply: (f) => setState(() => _filter = f),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final devicesAsync = ref.watch(adminDevicesProvider(null));

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: devicesAsync.when(
        loading: () => const _LoadingBody(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (all) {
          final filtered = _applyFilter(all);

          final faultyCount = all
              .where((d) => _deviceStatusFromKey(d.statusKey) == DeviceStatus.faulty)
              .length;

          final maintCount = all
              .where((d) => _deviceStatusFromKey(d.statusKey) == DeviceStatus.maintenance)
              .length;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                floating: false,
                elevation: 0,
                backgroundColor: const Color(0xFF1A237E),
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.maybePop(context),
                ),
                actions: [
                  _AppBarBtn(
                    label: l.isAr ? 'EN' : 'عربي',
                    isText: true,
                    onTap: () =>
                        LanguageController.of(context).toggleLanguage(),
                  ),
                  _AppBarBtn(
                    icon: Icons.tune_rounded,
                    badge: _filter.activeCount,
                    highlight: _filter.activeCount > 0,
                    onTap: () => _openFilter(all),
                  ),
                  _AppBarBtn(
                    icon: Icons.refresh_rounded,
                    onTap: () => ref.invalidate(adminDevicesProvider(null)),
                  ),
                  const SizedBox(width: 4),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: _DevicesAppBar(
                    isAr: l.isAr,
                    total: all.length,
                    faulty: faultyCount,
                    maint: maintCount,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _StatusTabRow(
                  selected: _filter.status,
                  isAr: l.isAr,
                  onSelect: (s) =>
                      setState(() => _filter = _filter.copyWith(status: s)),
                ),
              ),
              SliverToBoxAdapter(
                child: _DevSearchBar(
                  ctrl: _searchCtrl,
                  isAr: l.isAr,
                  filterCount: _filter.activeCount,
                  onFilterTap: () => _openFilter(all),
                ),
              ),
              if (!_filter.isEmpty)
                SliverToBoxAdapter(
                  child: _DevFilterChips(
                    filter: _filter,
                    isAr: l.isAr,
                    onRemove: (f) => setState(() => _filter = f),
                    onClearAll: () => setState(() => _filter = _filter.reset),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l.isAr
                              ? '${filtered.length} جهاز'
                              : '${filtered.length} devices',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A237E),
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      if (!_filter.isEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          l.isAr ? 'من ${all.length}' : 'of ${all.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              filtered.isEmpty
                  ? SliverFillRemaining(
                      child: _EmptyDevices(isAr: l.isAr),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (ctx, i) => _DeviceCard(
                          device: filtered[i],
                          index: i,
                          isAr: l.isAr,
                          onTap: () => _openDetail(ctx, filtered[i]),
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  void _openDetail(BuildContext ctx, AdminDeviceModel device) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _DeviceDetailSheet(device: device, isViewer: widget.isViewer),
    );
  }
}

class _DevicesAppBar extends StatelessWidget {
  final bool isAr;
  final int total;
  final int faulty;
  final int maint;

  const _DevicesAppBar({
    required this.isAr,
    required this.total,
    required this.faulty,
    required this.maint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1B5E), Color(0xFF1A237E), Color(0xFF283593)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
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
                        child: const Icon(
                          Icons.devices_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'جرد الأجهزة' : 'Asset Inventory',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            isAr
                                ? 'متابعة وتصفية حالة الأجهزة'
                                : 'Monitor & filter device status',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 12,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _ABPill(
                        value: total,
                        label: isAr ? 'جهاز' : 'Devices',
                        icon: Icons.devices_rounded,
                      ),
                      const SizedBox(width: 8),
                      if (faulty > 0)
                        _ABPill(
                          value: faulty,
                          label: isAr ? 'معطل' : 'Faulty',
                          icon: Icons.error_outline_rounded,
                          isAlert: true,
                        ),
                      const SizedBox(width: 8),
                      if (maint > 0)
                        _ABPill(
                          value: maint,
                          label: isAr ? 'صيانة' : 'Maint.',
                          icon: Icons.build_rounded,
                          color: Colors.amber,
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

class _ABPill extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final bool isAlert;
  final Color color;

  const _ABPill({
    required this.value,
    required this.label,
    required this.icon,
    this.isAlert = false,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final c = isAlert ? Colors.red.shade300 : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 5),
          Text(
            '$value $label',
            style: TextStyle(
              color: c,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBarBtn extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final bool isText;
  final int badge;
  final bool highlight;
  final VoidCallback onTap;

  const _AppBarBtn({
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: isText
                    ? Text(
                        label!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          fontFamily: 'Cairo',
                        ),
                      )
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
                  child: Text(
                    badge.toString(),
                    style: const TextStyle(
                      color: Color(0xFF1A237E),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusTabRow extends StatelessWidget {
  final String selected;
  final bool isAr;
  final ValueChanged<String> onSelect;

  const _StatusTabRow({
    required this.selected,
    required this.isAr,
    required this.onSelect,
  });

  static const _tabs = [
    ('ALL', 'All', 'الكل', Color(0xFF1A237E), Icons.all_inclusive_rounded),
    ('OK', 'OK', 'يعمل', Color(0xFF2E7D32), Icons.check_circle_rounded),
    ('FAULTY', 'Faulty', 'معطل', Color(0xFFC62828), Icons.error_rounded),
    ('MAINTENANCE', 'Maint.', 'صيانة', Color(0xFFE65100), Icons.build_rounded),
    ('OFFLINE', 'Offline', 'غير متصل', Color(0xFF455A64), Icons.wifi_off_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _tabs.map((tab) {
            final isSelected = selected == tab.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(tab.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? tab.$4.withOpacity(0.1)
                        : const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? tab.$4.withOpacity(0.6)
                          : const Color(0xFFDDE5FF),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.$5,
                        size: 14,
                        color: isSelected ? tab.$4 : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isAr ? tab.$3 : tab.$2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? tab.$4 : Colors.grey.shade500,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _DevSearchBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool isAr;
  final int filterCount;
  final VoidCallback onFilterTap;

  const _DevSearchBar({
    required this.ctrl,
    required this.isAr,
    required this.filterCount,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
                controller: ctrl,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Cairo',
                  color: Color(0xFF0D1B5E),
                ),
                decoration: InputDecoration(
                  hintText: isAr
                      ? 'بحث بالكود، الاسم، الموقع...'
                      : 'Search code, name, location...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                    fontFamily: 'Cairo',
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF1A237E),
                    size: 20,
                  ),
                  suffixIcon: ctrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: ctrl.clear,
                          color: Colors.grey.shade400,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 13,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onFilterTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: filterCount > 0
                    ? const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF1A237E), Color(0xFF283593)],
                      ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (filterCount > 0
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF1A237E))
                        .withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                  if (filterCount > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      filterCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
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

class _DevFilterChips extends StatelessWidget {
  final _DeviceFilter filter;
  final bool isAr;
  final ValueChanged<_DeviceFilter> onRemove;
  final VoidCallback onClearAll;

  const _DevFilterChips({
    required this.filter,
    required this.isAr,
    required this.onRemove,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (filter.status != 'ALL')
              _DChip(
                label: filter.status,
                onRemove: () => onRemove(filter.copyWith(status: 'ALL')),
              ),
            if (filter.building != 'ALL')
              _DChip(
                label: filter.building,
                onRemove: () => onRemove(filter.copyWith(building: 'ALL')),
              ),
            if (filter.type != 'ALL')
              _DChip(
                label: filter.type,
                onRemove: () => onRemove(filter.copyWith(type: 'ALL')),
              ),
            if (filter.location != 'ALL')
              _DChip(
                label: filter.location,
                onRemove: () => onRemove(filter.copyWith(location: 'ALL')),
              ),
            if (filter.hasRecentInspection)
              _DChip(
                label: isAr ? 'مفتوش حديثاً' : 'Recently inspected',
                color: Colors.green.shade700,
                onRemove: () =>
                    onRemove(filter.copyWith(hasRecentInspection: false)),
              ),
            GestureDetector(
              onTap: onClearAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.clear_all_rounded,
                      size: 14,
                      color: Colors.red.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAr ? 'مسح الكل' : 'Clear all',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]
              .map(
                (w) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: w,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _DChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onRemove;

  const _DChip({
    required this.label,
    this.color = const Color(0xFF1A237E),
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 14, color: color),
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final AdminDeviceModel device;
  final int index;
  final bool isAr;
  final VoidCallback onTap;

  const _DeviceCard({
    required this.device,
    required this.index,
    required this.isAr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = _deviceStatusFromKey(device.statusKey);
    final hasIssue =
        status == DeviceStatus.faulty || status == DeviceStatus.maintenance;

    final (Color accentColor, Color accentBg, IconData statusIcon) = switch (status) {
      DeviceStatus.faulty => (
          Colors.red.shade600,
          Colors.red.shade50,
          Icons.error_rounded
        ),
      DeviceStatus.maintenance => (
          Colors.orange.shade700,
          Colors.orange.shade50,
          Icons.build_rounded
        ),
      _ => (
          const Color(0xFF2E7D32),
          const Color(0xFFE8F5E9),
          Icons.check_circle_rounded
        ),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasIssue
                ? accentColor.withOpacity(0.3)
                : const Color(0xFFE8EDFF),
            width: hasIssue ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: hasIssue
                  ? accentColor.withOpacity(0.06)
                  : const Color(0xFF1A237E).withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Container(
                height: 3,
                color: accentColor,
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: accentBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            hasIssue
                                ? Icons.warning_rounded
                                : Icons.camera_alt_rounded,
                            color: accentColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0D1B5E),
                                  fontFamily: 'Cairo',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F4FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  device.deviceCode,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: Color(0xFF1A237E),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _StatusBadgeNew(
                              status: status,
                              labelAr: device.statusAr,
                            ),
                            if (device.lastInspectionAt != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                '${device.lastInspectionAt!.day}/${device.lastInspectionAt!.month}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    if (device.locationName != null ||
                        device.locationBuilding != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (device.locationName != null)
                              _LocTag(
                                icon: Icons.hub_rounded,
                                text: device.locationName!
                                    .split('—')
                                    .first
                                    .trim(),
                                color: const Color(0xFF283593),
                              ),
                            if (device.locationBuilding?.isNotEmpty == true)
                              _LocTag(
                                icon: Icons.business_rounded,
                                text: device.locationBuilding!,
                                color: const Color(0xFF1565C0),
                                isRtl: true,
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
      ),
    )
        .animate(delay: Duration(milliseconds: 60 + index * 35))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.04, curve: Curves.easeOut);
  }
}

class _StatusBadgeNew extends StatelessWidget {
  final DeviceStatus status;
  final String labelAr;

  const _StatusBadgeNew({
    required this.status,
    required this.labelAr,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (Color c, Color bg, String en) = switch (status) {
      DeviceStatus.faulty => (
          Colors.red.shade700,
          Colors.red.shade50,
          'Faulty'
        ),
      DeviceStatus.maintenance => (
          Colors.orange.shade700,
          Colors.orange.shade50,
          'Maint.'
        ),
      DeviceStatus.underReview => (
          Colors.blueGrey.shade700,
          Colors.blueGrey.shade50,
          'Review'
        ),
      DeviceStatus.needsMaintenance => (
          Colors.orange.shade700,
          Colors.orange.shade50,
          'Needs Maint.'
        ),
      _ => (
          Colors.green.shade700,
          Colors.green.shade50,
          'OK'
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(
        l.isAr ? labelAr : en,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: c,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}

class _LocTag extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isRtl;

  const _LocTag({
    required this.icon,
    required this.text,
    required this.color,
    this.isRtl = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
          text,
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}

class _DeviceFilterSheet extends StatefulWidget {
  final List<AdminDeviceModel> devices;
  final _DeviceFilter current;
  final ValueChanged<_DeviceFilter> onApply;

  const _DeviceFilterSheet({
    required this.devices,
    required this.current,
    required this.onApply,
  });

  @override
  State<_DeviceFilterSheet> createState() => _DeviceFilterSheetState();
}

class _DeviceFilterSheetState extends State<_DeviceFilterSheet> {
  late _DeviceFilter _local;

  @override
  void initState() {
    super.initState();
    _local = widget.current;
  }

  List<String> _unique(String? Function(AdminDeviceModel) f) => widget.devices
      .map(f)
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final buildings = _unique((d) => d.locationBuilding);
    final types = _unique((d) => d.typeName);
    final locations = _unique((d) => d.locationName);

    const statusOpts = [
      ('ALL', 'All', 'الكل', Color(0xFF1A237E)),
      ('OK', 'OK', 'يعمل', Color(0xFF2E7D32)),
      ('FAULTY', 'Faulty', 'معطل', Color(0xFFC62828)),
      ('MAINTENANCE', 'Maintenance', 'صيانة', Color(0xFFE65100)),
      ('OFFLINE', 'Offline', 'غير متصل', Color(0xFF455A64)),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF0F4FF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D1B5E), Color(0xFF1A237E)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.isAr ? 'فلتر الأجهزة' : 'Device Filters',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            Text(
                              l.isAr
                                  ? 'تصفية دقيقة لكل حقل'
                                  : 'Precise field-level filtering',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 12,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (_local.activeCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade400,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_local.activeCount} ${l.isAr ? "فعّال" : "active"}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                children: [
                  _SheetSection(
                    title: l.isAr ? 'الحالة' : 'Status',
                    icon: Icons.health_and_safety_rounded,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: statusOpts.map((opt) {
                        final sel = _local.status == opt.$1;
                        return GestureDetector(
                          onTap: () => setState(
                            () => _local = _local.copyWith(status: opt.$1),
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: sel
                                  ? opt.$4.withOpacity(0.1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: sel
                                    ? opt.$4.withOpacity(0.6)
                                    : const Color(0xFFDDE5FF),
                                width: sel ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              l.isAr ? opt.$3 : opt.$2,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    sel ? FontWeight.w800 : FontWeight.w500,
                                color: sel ? opt.$4 : Colors.grey.shade500,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SheetSection(
                    title: l.isAr ? 'المبنى' : 'Building',
                    icon: Icons.business_rounded,
                    child: _SheetDropdown(
                      value: _local.building,
                      allLabel: l.isAr ? 'كل المباني' : 'All Buildings',
                      items: buildings,
                      onChanged: (v) =>
                          setState(() => _local = _local.copyWith(building: v)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SheetSection(
                    title: l.isAr ? 'نوع الجهاز' : 'Device Type',
                    icon: Icons.memory_rounded,
                    child: _SheetDropdown(
                      value: _local.type,
                      allLabel: l.isAr ? 'كل الأنواع' : 'All Types',
                      items: types,
                      onChanged: (v) =>
                          setState(() => _local = _local.copyWith(type: v)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SheetSection(
                    title: l.isAr ? 'الموقع' : 'Location',
                    icon: Icons.place_rounded,
                    child: _SheetDropdown(
                      value: _local.location,
                      allLabel: l.isAr ? 'كل المواقع' : 'All Locations',
                      items: locations,
                      onChanged: (v) => setState(
                        () => _local = _local.copyWith(location: v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SheetSection(
                    title: l.isAr ? 'حالة الفحص' : 'Inspection Status',
                    icon: Icons.fact_check_rounded,
                    child: GestureDetector(
                      onTap: () => setState(
                        () => _local = _local.copyWith(
                          hasRecentInspection: !_local.hasRecentInspection,
                        ),
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _local.hasRecentInspection
                              ? Colors.green.shade50
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _local.hasRecentInspection
                                ? Colors.green.shade300
                                : const Color(0xFFDDE5FF),
                            width: _local.hasRecentInspection ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              color: _local.hasRecentInspection
                                  ? Colors.green.shade600
                                  : Colors.grey.shade400,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l.isAr
                                    ? 'أجهزة مفتوشة خلال آخر 30 يوم'
                                    : 'Inspected in last 30 days',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _local.hasRecentInspection
                                      ? Colors.green.shade700
                                      : const Color(0xFF0D1B5E),
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                            Switch(
                              value: _local.hasRecentInspection,
                              onChanged: (v) => setState(
                                () => _local = _local.copyWith(
                                  hasRecentInspection: v,
                                ),
                              ),
                              activeColor: Colors.green.shade600,
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
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _local = const _DeviceFilter()),
                      icon: const Icon(Icons.restart_alt_rounded, size: 18),
                      label: Text(
                        l.isAr ? 'إعادة ضبط' : 'Reset',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A237E),
                        side: const BorderSide(color: Color(0xFFB0BEE8)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        widget.onApply(_local);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        l.isAr ? 'تطبيق الفلتر' : 'Apply Filters',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

class _SheetSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SheetSection({
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
            Icon(icon, size: 15, color: const Color(0xFF1A237E)),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D1B5E),
                fontFamily: 'Cairo',
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

class _SheetDropdown extends StatelessWidget {
  final String value;
  final String allLabel;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _SheetDropdown({
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
              ? const Color(0xFF1A237E).withOpacity(0.4)
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
                ? const Color(0xFF1A237E)
                : Colors.grey.shade400,
          ),
          items: [
            DropdownMenuItem(
              value: 'ALL',
              child: Text(
                allLabel,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontFamily: 'Cairo',
                  fontSize: 13,
                ),
              ),
            ),
            ...items.map(
              (item) => DropdownMenuItem(
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
              ),
            ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _DeviceDetailSheet extends ConsumerWidget {
  final AdminDeviceModel device;
  final bool isViewer;

  const _DeviceDetailSheet({
    required this.device,
    this.isViewer = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final history = ref.watch(deviceHistoryProvider(device.id));
    final tasks = ref.watch(tasksByDeviceProvider(device.id));
    final status = _deviceStatusFromKey(device.statusKey);
    final hasIssue =
        status == DeviceStatus.faulty || status == DeviceStatus.maintenance;
    final accentColor =
        hasIssue ? Colors.orange.shade700 : const Color(0xFF1A237E);

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF0F4FF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFEEF1FF)),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            hasIssue
                                ? Icons.warning_rounded
                                : Icons.camera_alt_rounded,
                            color: accentColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0D1B5E),
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              Text(
                                device.deviceCode,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: accentColor,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _StatusBadgeNew(
                          status: status,
                          labelAr: device.statusAr,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(16),
                children: [
                  _DetailCard(
                    children: [
                      _DetailRow(l.isAr ? 'الكود' : 'Code', device.deviceCode),
                      _DetailRow(
                        l.isAr ? 'السيريال' : 'Serial',
                        device.serialNumber,
                      ),
                      if (device.typeName != null)
                        _DetailRow(
                          l.isAr ? 'النوع' : 'Type',
                          device.typeName!,
                        ),
                      if (device.locationName?.isNotEmpty == true)
                        _DetailRow(
                          l.isAr ? 'الموقع' : 'Location',
                          device.locationName!,
                        ),
                      if (device.lastInspectorName != null)
                        _DetailRow(
                          l.isAr ? 'آخر فني' : 'Last Inspector',
                          device.lastInspectorName!,
                        ),
                      if (device.lastInspectionAt != null)
                        _DetailRow(
                          l.isAr ? 'آخر تفتيش' : 'Last Inspection',
                          '${device.lastInspectionAt!.day}/${device.lastInspectionAt!.month}/${device.lastInspectionAt!.year}',
                        ),
                      _DetailRow(
                        l.isAr ? 'عدد الفحوصات' : 'Inspection Count',
                        device.inspectionCount.toString(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // ── Last Activity Hero ─────────────────
                  _DeviceLastActivityCard(
                    device: device,
                    isAr: l.isAr,
                  ),
                  const SizedBox(height: 14),

                  // ── Device Health Snapshot ─────────────
                  tasks.when(
                    loading: () => const AdminShimmerList(count: 1),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (list) => _DeviceRecentActivityCard(
                      device: device,
                      tasks: list,
                      isAr: l.isAr,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DeviceHealthSnapshot(
                    device: device,
                    history: history.valueOrNull ?? [],
                    isAr: l.isAr,
                  ),
                  const SizedBox(height: 14),
                  _SectionTitle(
                    title: l.isAr ? 'سجل الحالة' : 'Status History',
                    icon: Icons.history_rounded,
                  ),
                  const SizedBox(height: 8),
                  history.when(
                    loading: () => const AdminShimmerList(count: 3),
                    error: (e, _) => Text(e.toString(), style: AppText.small),
                    data: (list) => list.isEmpty
                        ? Center(
                            child: Text(
                              l.isAr ? 'لا يوجد سجل' : 'No history',
                              style: AppText.small,
                            ),
                          )
                        : Column(
                            children: list
                                .map(
                                  (h) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE8EDFF),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1A237E)
                                                  .withOpacity(0.3),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${h.oldStatus} → ${h.newStatus}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 13,
                                                    color: Color(0xFF0D1B5E),
                                                    fontFamily: 'Cairo',
                                                  ),
                                                ),
                                                if (h.changedByName != null)
                                                  Text(
                                                    h.changedByName!,
                                                    style: AppText.small,
                                                  ),
                                                if (h.note?.isNotEmpty == true)
                                                  Text(
                                                    h.note!,
                                                    style: AppText.caption,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '${h.changedAt.day}/${h.changedAt.month}',
                                            style: AppText.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;

  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDFF)),
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0F4FF)),
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontFamily: 'Cairo',
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D1B5E),
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1A237E)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0D1B5E),
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}

class _EmptyDevices extends StatelessWidget {
  final bool isAr;

  const _EmptyDevices({required this.isAr});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFE8EDFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.devices_other_rounded,
                size: 36,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isAr ? 'لا توجد أجهزة مطابقة' : 'No devices found',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D1B5E),
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isAr ? 'جرّب تعديل الفلاتر' : 'Try adjusting your filters',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      );
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A237E)),
      );
}

// ══════════════════════════════════════════════════════════
//  DEVICE LAST ACTIVITY CARD
// ══════════════════════════════════════════════════════════
class _DeviceLastActivityCard extends StatelessWidget {
  final AdminDeviceModel device;
  final bool isAr;
  const _DeviceLastActivityCard({required this.device, required this.isAr});

  String _timeAgo(DateTime dt, bool isAr) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return isAr
          ? 'منذ ${diff.inMinutes} دقيقة'
          : '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return isAr ? 'منذ ${diff.inHours} ساعة' : '${diff.inHours}h ago';
    } else {
      return isAr ? 'منذ ${diff.inDays} يوم' : '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasInsp = device.lastInspectionAt != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A237E).withOpacity(0.08),
            const Color(0xFF00C9A7).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.access_time_rounded,
                  color: const Color(0xFF1A237E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'آخر فحص مسجّل' : 'Last Inspection',
                      style: TextStyle(
                        color: const Color(0xFF0D1B5E).withOpacity(0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasInsp
                          ? _timeAgo(device.lastInspectionAt!, isAr)
                          : (isAr ? 'لا يوجد فحص سابق' : 'Never inspected'),
                      style: const TextStyle(
                        color: Color(0xFF0D1B5E),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (device.lastInspectorName != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person_rounded,
                              size: 11,
                              color: const Color(0xFF1A237E).withOpacity(0.5)),
                          const SizedBox(width: 4),
                          Text(
                            device.lastInspectorName!,
                            style: TextStyle(
                              color: const Color(0xFF1A237E).withOpacity(0.65),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (hasInsp)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${device.lastInspectionAt!.day}/${device.lastInspectionAt!.month}',
                      style: TextStyle(
                        color: const Color(0xFF1A237E).withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${device.lastInspectionAt!.hour.toString().padLeft(2, '0')}:${device.lastInspectionAt!.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: const Color(0xFF1A237E).withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  DEVICE HEALTH SNAPSHOT
// ══════════════════════════════════════════════════════════
class _DeviceRecentActivityCard extends StatelessWidget {
  final AdminDeviceModel device;
  final List<TaskModel> tasks;
  final bool isAr;

  const _DeviceRecentActivityCard({
    required this.device,
    required this.tasks,
    required this.isAr,
  });

  String _timeAgo(DateTime dt, bool isAr) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return isAr ? 'منذ ${diff.inMinutes} دقيقة' : '${diff.inMinutes} min ago';
    }
    if (diff.inHours < 24) {
      return isAr ? 'منذ ${diff.inHours} ساعة' : '${diff.inHours}h ago';
    }
    return isAr ? 'منذ ${diff.inDays} يوم' : '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final recent = [...tasks]
      ..sort((a, b) => (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));
    final latest = recent.isEmpty ? null : recent.first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.pending_actions_rounded, color: Color(0xFF1A237E), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAr ? 'آخر متابعة على هذا الجهاز' : 'Latest follow-up on this device',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D1B5E),
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (latest == null)
            Text(
              isAr ? 'لا توجد متابعات مرتبطة بهذا الجهاز حالياً' : 'No linked follow-ups yet',
              style: AppText.small,
            )
          else ...[
            Text(
              latest.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0D1B5E),
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isAr ? 'آخر نشاط تم هنا مع ${device.name}' : 'Latest activity happened here with ${device.name}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DeviceActivityChip(
                  icon: Icons.person_rounded,
                  text: latest.assignedToName ?? (isAr ? 'بدون فني' : 'No technician'),
                ),
                _DeviceActivityChip(
                  icon: Icons.flag_rounded,
                  text: isAr ? latest.statusAr : latest.statusEn,
                ),
                _DeviceActivityChip(
                  icon: Icons.access_time_rounded,
                  text: _timeAgo(latest.completedAt ?? latest.createdAt, isAr),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DeviceActivityChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DeviceActivityChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E).withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF1A237E)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A237E),
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceHealthSnapshot extends StatelessWidget {
  final AdminDeviceModel device;
  final List<DeviceHistoryItem> history;
  final bool isAr;
  const _DeviceHealthSnapshot({
    required this.device,
    required this.history,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    final isOk = device.currentStatus.toUpperCase() == 'OK';
    final isMaint = device.currentStatus.toUpperCase().contains('MAINTENANCE');
    final isOut = device.currentStatus.toUpperCase() == 'OUT_OF_SERVICE';

    final color = isOk
        ? const Color(0xFF00695C)
        : isMaint
            ? Colors.orange.shade700
            : Colors.red.shade700;

    final healthPct = isOk ? 1.0 : isMaint ? 0.5 : 0.15;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety_rounded, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                isAr ? 'صحة الجهاز' : 'Device Health',
                style: TextStyle(
                  color: const Color(0xFF0D1B5E),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(healthPct * 100).toInt()}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: healthPct,
              minHeight: 7,
              backgroundColor: const Color(0xFFEEF1FF),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 14),
          // Stats row
          Row(
            children: [
              _DevStatChip(
                label: isAr ? 'فحوصات' : 'Inspections',
                value: '${device.inspectionCount}',
                icon: Icons.fact_check_rounded,
                color: const Color(0xFF1A237E),
              ),
              const SizedBox(width: 8),
              _DevStatChip(
                label: isAr ? 'أعطال مسجلة' : 'Faults',
                value: '${device.faultCount}',
                icon: Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              _DevStatChip(
                label: isAr ? 'تغييرات' : 'Changes',
                value: '${history.length}',
                icon: Icons.history_rounded,
                color: const Color(0xFF00695C),
              ),
            ],
          ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: const Color(0xFFF0F4FF),
            ),
            const SizedBox(height: 10),
            Text(
              isAr ? 'آخر تغيير في الحالة' : 'Latest Status Change',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      history.last.oldStatus,
                      style: const TextStyle(
                        color: Color(0xFF0D1B5E),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward_rounded,
                        size: 12, color: Colors.grey.shade400),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      history.last.newStatus,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${history.last.changedAt.day}/${history.last.changedAt.month}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DevStatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _DevStatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
