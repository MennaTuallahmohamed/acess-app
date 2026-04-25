import 'package:access_track/admin/admin_models.dart';
import 'package:access_track/admin/admin_providers.dart';
import 'package:access_track/admin/admin_widgets.dart';
import 'package:access_track/app_localizations.dart';
import 'package:access_track/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminTasksScreen extends ConsumerStatefulWidget {
  final String? initialFilter;
  final bool isViewer;

  const AdminTasksScreen({
    super.key,
    this.initialFilter,
    this.isViewer = false,
  });

  @override
  ConsumerState<AdminTasksScreen> createState() => _AdminTasksScreenState();
}

class _AdminTasksScreenState extends ConsumerState<AdminTasksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  String _search = '';
  String? _filterTechId;
  String? _filterDeviceId;
  String? _filterCluster;
  String? _filterBuilding;
  String? _inspectionStatus;
  bool _showFilters = false;

  final _searchCtrl = TextEditingController();

  static const _tabsStatus = <String>[
    'ALL',
    'PENDING',
    'IN_PROGRESS',
    'COMPLETED',
    'OVERDUE',
    'URGENT',
    'INSPECTIONS',
  ];

  @override
  void initState() {
    super.initState();
    final initial = (widget.initialFilter ?? 'ALL').toUpperCase();
    final index = _tabsStatus.indexOf(initial);
    _tabs = TabController(
      length: _tabsStatus.length,
      vsync: this,
      initialIndex: index < 0 ? 0 : index,
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  int get _activeFilterCount {
    return [
      _search.trim().isEmpty ? null : _search,
      _filterTechId,
      _filterDeviceId,
      _filterCluster,
      _filterBuilding,
      _inspectionStatus,
    ].where((e) => e != null).length;
  }

  AdminInspectionFilter get _inspectionFilter {
    return AdminInspectionFilter(
      technicianId: _filterTechId,
      deviceId: _filterDeviceId,
      status: _inspectionStatus,
    );
  }

  void _clearFilters() {
    setState(() {
      _search = '';
      _filterTechId = null;
      _filterDeviceId = null;
      _filterCluster = null;
      _filterBuilding = null;
      _inspectionStatus = null;
      _searchCtrl.clear();
    });
  }

  void _refreshAll() {
    ref.invalidate(allTasksProvider);
    ref.invalidate(adminStatsProvider);
    ref.invalidate(adminAnalyticsProvider);
    ref.invalidate(activeTechniciansProvider);
    ref.invalidate(techniciansProvider);
    ref.invalidate(adminDevicesProvider(null));
    ref.invalidate(locationsProvider);
    ref.invalidate(adminInspectionsProvider(_inspectionFilter));
    ref.invalidate(monthlyInspectionsProvider);

    for (final status in _tabsStatus) {
      if (status != 'ALL' && status != 'INSPECTIONS') {
        ref.invalidate(tasksByStatusProvider(status));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tasksAsync = ref.watch(allTasksProvider);
    final inspectionsAsync = ref.watch(adminInspectionsProvider(_inspectionFilter));
    final techniciansAsync = ref.watch(activeTechniciansProvider);
    final devicesAsync = ref.watch(adminDevicesProvider(null));
    final locationsAsync = ref.watch(locationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: widget.isViewer
          ? null
          : FloatingActionButton.extended(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_task_rounded),
              label: Text(l.isAr ? 'مهمة جديدة' : 'New Task'),
              onPressed: () => _showCreateTaskSheet(context),
            ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              isAr: l.isAr,
              activeFilterCount: _activeFilterCount,
              showFilters: _showFilters,
              onBack: () => Navigator.maybePop(context),
              onRefresh: _refreshAll,
              onToggleFilters: () => setState(() => _showFilters = !_showFilters),
              onCreate: widget.isViewer ? null : () => _showCreateTaskSheet(context),
            ),
            _SummaryBar(
              tasksAsync: tasksAsync,
              inspectionsAsync: inspectionsAsync,
            ),
            if (_showFilters)
              _FiltersPanel(
                searchCtrl: _searchCtrl,
                techniciansAsync: techniciansAsync,
                devicesAsync: devicesAsync,
                locationsAsync: locationsAsync,
                filterTechId: _filterTechId,
                filterDeviceId: _filterDeviceId,
                filterCluster: _filterCluster,
                filterBuilding: _filterBuilding,
                inspectionStatus: _inspectionStatus,
                activeFilterCount: _activeFilterCount,
                onSearch: (v) => setState(() => _search = v),
                onTech: (v) => setState(() => _filterTechId = v),
                onDevice: (v) => setState(() => _filterDeviceId = v),
                onCluster: (v) => setState(() {
                  _filterCluster = v;
                  _filterBuilding = null;
                }),
                onBuilding: (v) => setState(() => _filterBuilding = v),
                onInspectionStatus: (v) => setState(() => _inspectionStatus = v),
                onClear: _clearFilters,
              ).animate().fadeIn(duration: 180.ms).slideY(begin: -0.05),
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: const Color(0xFF1A237E),
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorColor: const Color(0xFF1A237E),
                indicatorWeight: 3,
                tabs: [
                  _tab(Icons.all_inbox_rounded, l.isAr ? 'كل المهام' : 'All Tasks'),
                  _tab(Icons.hourglass_empty_rounded, l.isAr ? 'معلقة' : 'Pending'),
                  _tab(Icons.play_circle_rounded, l.isAr ? 'جارية' : 'In progress'),
                  _tab(Icons.check_circle_rounded, l.isAr ? 'مكتملة' : 'Completed'),
                  _tab(Icons.timer_off_rounded, l.isAr ? 'متأخرة' : 'Overdue'),
                  _tab(Icons.bolt_rounded, l.isAr ? 'طارئة' : 'Urgent'),
                  _tab(Icons.fact_check_rounded, l.isAr ? 'التفتيشات التي تمت' : 'Done Inspections'),
                ],
              ),
            ),
            Expanded(
              child: tasksAsync.when(
                loading: () => const _LoadingList(),
                error: (e, _) => _ErrorState(message: e.toString(), onRetry: _refreshAll),
                data: (tasks) => TabBarView(
                  controller: _tabs,
                  children: _tabsStatus.map((status) {
                    if (status == 'INSPECTIONS') {
                      return inspectionsAsync.when(
                        loading: () => const _LoadingList(),
                        error: (e, _) => _ErrorState(message: e.toString(), onRetry: _refreshAll),
                        data: (inspections) => _InspectionList(
                          inspections: inspections,
                          search: _search,
                          filterCluster: _filterCluster,
                          filterBuilding: _filterBuilding,
                          onRefresh: _refreshAll,
                        ),
                      );
                    }

                    return _TaskList(
                      status: status,
                      tasks: tasks,
                      search: _search,
                      filterTechId: _filterTechId,
                      filterDeviceId: _filterDeviceId,
                      filterCluster: _filterCluster,
                      filterBuilding: _filterBuilding,
                      isViewer: widget.isViewer,
                      onRefresh: _refreshAll,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Tab _tab(IconData icon, String label) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        maxChildSize: 0.97,
        minChildSize: 0.55,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.only(top: 8, bottom: 40),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              CreateTaskForm(
                onSubmit: (req) async {
                  await ref.read(adminRepoProvider).createTask(req);
                  _refreshAll();
                  if (mounted) Navigator.pop(context);
                },
                onCancel: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isAr;
  final int activeFilterCount;
  final bool showFilters;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback onToggleFilters;
  final VoidCallback? onCreate;

  const _Header({
    required this.isAr,
    required this.activeFilterCount,
    required this.showFilters,
    required this.onBack,
    required this.onRefresh,
    required this.onToggleFilters,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          _IconButtonLite(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          const SizedBox(width: 10),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.task_alt_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'المهام والتفتيشات' : 'Tasks & Inspections',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                  ),
                ),
                Text(
                  isAr
                      ? 'المهام التي أنشأتيها + التفتيشات التي تمت فعلاً'
                      : 'Created tasks + completed field inspections',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontFamily: 'Cairo',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _IconButtonLite(
            icon: showFilters ? Icons.filter_list_off_rounded : Icons.filter_list_rounded,
            badge: activeFilterCount,
            active: showFilters || activeFilterCount > 0,
            onTap: onToggleFilters,
          ),
          const SizedBox(width: 6),
          _IconButtonLite(icon: Icons.refresh_rounded, onTap: onRefresh),
          if (onCreate != null) ...[
            const SizedBox(width: 6),
            _IconButtonLite(icon: Icons.add_rounded, onTap: onCreate!),
          ],
        ],
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final AsyncValue<List<TaskModel>> tasksAsync;
  final AsyncValue<List<InspectionDetail>> inspectionsAsync;

  const _SummaryBar({
    required this.tasksAsync,
    required this.inspectionsAsync,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = AppLocalizations.of(context).isAr;

    final tasks = tasksAsync.valueOrNull ?? [];
    final inspections = inspectionsAsync.valueOrNull ?? [];

    int countTask(String s) => tasks.where((t) => t.status.toUpperCase() == s).length;
    final urgent = tasks.where((t) {
      return t.isUrgent || t.isEmergency || t.priority.toUpperCase() == 'URGENT';
    }).length;

    final okInspections = inspections.where((i) => i.inspectionStatus.toUpperCase() == 'OK').length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Row(
        children: [
          Expanded(child: _MiniMetric(label: isAr ? 'كل المهام' : 'Tasks', value: tasks.length, color: const Color(0xFF1A237E))),
          Expanded(child: _MiniMetric(label: isAr ? 'تمت' : 'Done', value: countTask('COMPLETED'), color: const Color(0xFF16A34A))),
          Expanded(child: _MiniMetric(label: isAr ? 'جارية' : 'Running', value: countTask('IN_PROGRESS'), color: const Color(0xFF0284C7))),
          Expanded(child: _MiniMetric(label: isAr ? 'طارئة' : 'Urgent', value: urgent, color: const Color(0xFFDC2626))),
          Expanded(child: _MiniMetric(label: isAr ? 'تفتيش' : 'Inspections', value: inspections.length, color: const Color(0xFF7C3AED))),
          Expanded(child: _MiniMetric(label: isAr ? 'سليم' : 'OK', value: okInspections, color: const Color(0xFF059669))),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MiniMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              fontFamily: 'Cairo',
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersPanel extends StatelessWidget {
  final TextEditingController searchCtrl;
  final AsyncValue<List<TechnicianModel>> techniciansAsync;
  final AsyncValue<List<AdminDeviceModel>> devicesAsync;
  final AsyncValue<List<LocationModel>> locationsAsync;
  final String? filterTechId;
  final String? filterDeviceId;
  final String? filterCluster;
  final String? filterBuilding;
  final String? inspectionStatus;
  final int activeFilterCount;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onTech;
  final ValueChanged<String?> onDevice;
  final ValueChanged<String?> onCluster;
  final ValueChanged<String?> onBuilding;
  final ValueChanged<String?> onInspectionStatus;
  final VoidCallback onClear;

  const _FiltersPanel({
    required this.searchCtrl,
    required this.techniciansAsync,
    required this.devicesAsync,
    required this.locationsAsync,
    required this.filterTechId,
    required this.filterDeviceId,
    required this.filterCluster,
    required this.filterBuilding,
    required this.inspectionStatus,
    required this.activeFilterCount,
    required this.onSearch,
    required this.onTech,
    required this.onDevice,
    required this.onCluster,
    required this.onBuilding,
    required this.onInspectionStatus,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = AppLocalizations.of(context).isAr;
    final technicians = techniciansAsync.valueOrNull ?? [];
    final devices = devicesAsync.valueOrNull ?? [];
    final locations = locationsAsync.valueOrNull ?? [];

    final clusters = locations
        .map((e) => e.cluster)
        .whereType<String>()
        .where((e) => e.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final buildings = locations
        .where((e) => filterCluster == null || e.cluster == filterCluster)
        .map((e) => e.building)
        .whereType<String>()
        .where((e) => e.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        children: [
          TextField(
            controller: searchCtrl,
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: isAr
                  ? 'بحث بالعنوان / الفني / الجهاز / كود الجهاز / التقرير...'
                  : 'Search title / technician / device / code / report...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Drop<String>(
                  value: technicians.any((e) => e.id == filterTechId) ? filterTechId : null,
                  hint: isAr ? 'الفنيين فقط' : 'Technicians only',
                  items: technicians.map((t) => _DropItem(t.id, t.fullName)).toList(),
                  onChanged: onTech,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Drop<String>(
                  value: devices.any((e) => e.id == filterDeviceId) ? filterDeviceId : null,
                  hint: isAr ? 'الجهاز' : 'Device',
                  items: devices.map((d) => _DropItem(d.id, '${d.name} (${d.deviceCode})')).toList(),
                  onChanged: onDevice,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Drop<String>(
                  value: clusters.contains(filterCluster) ? filterCluster : null,
                  hint: isAr ? 'الكلستر' : 'Cluster',
                  items: clusters.map((e) => _DropItem(e, e)).toList(),
                  onChanged: onCluster,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Drop<String>(
                  value: buildings.contains(filterBuilding) ? filterBuilding : null,
                  hint: isAr ? 'المبنى' : 'Building',
                  items: buildings.map((e) => _DropItem(e, e)).toList(),
                  onChanged: onBuilding,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Drop<String>(
            value: _inspectionStatuses.any((e) => e.value == inspectionStatus) ? inspectionStatus : null,
            hint: isAr ? 'فلتر حالة التفتيش' : 'Inspection status filter',
            items: _inspectionStatuses.map((e) => _DropItem(e.value, isAr ? e.ar : e.en)).toList(),
            onChanged: onInspectionStatus,
          ),
          if (activeFilterCount > 0) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 16),
                label: Text(isAr ? 'مسح الفلاتر' : 'Clear filters'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskList extends ConsumerWidget {
  final String status;
  final List<TaskModel> tasks;
  final String search;
  final String? filterTechId;
  final String? filterDeviceId;
  final String? filterCluster;
  final String? filterBuilding;
  final bool isViewer;
  final VoidCallback onRefresh;

  const _TaskList({
    required this.status,
    required this.tasks,
    required this.search,
    required this.filterTechId,
    required this.filterDeviceId,
    required this.filterCluster,
    required this.filterBuilding,
    required this.isViewer,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = AppLocalizations.of(context).isAr;
    final devices = ref.watch(adminDevicesProvider(null)).valueOrNull ?? [];
    final locations = ref.watch(locationsProvider).valueOrNull ?? [];
    final filtered = _filter(tasks, devices, locations);

    if (filtered.isEmpty) return _EmptyTasks(isAr: isAr, status: status);

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final task = filtered[i];
          return _TaskCard(
            task: task,
            isAr: isAr,
            index: i,
            onTap: () => _openTaskSheet(context, ref, task),
          );
        },
      ),
    );
  }

  List<TaskModel> _filter(
    List<TaskModel> list,
    List<AdminDeviceModel> devices,
    List<LocationModel> locations,
  ) {
    final q = search.trim().toLowerCase();
    return list.where((t) {
      final s = t.status.toUpperCase();
      final urgent = t.isUrgent ||
          t.isEmergency ||
          t.priority.toUpperCase() == 'URGENT' ||
          s == 'URGENT';

      if (status != 'ALL') {
        if (status == 'URGENT') {
          if (!urgent) return false;
        } else if (s != status) {
          return false;
        }
      }

      if (filterTechId != null && t.assignedToId != filterTechId) return false;
      if (filterDeviceId != null && t.deviceId != filterDeviceId) return false;

      final device = devices.firstWhereOrNull((d) => d.id == t.deviceId);
      final loc = locations.firstWhereOrNull((l) {
        return l.id == t.locationId || l.id == device?.locationId;
      });

      if (filterCluster != null && loc?.cluster != filterCluster) return false;
      if (filterBuilding != null && loc?.building != filterBuilding) return false;

      if (q.isNotEmpty) {
        final haystack = [
          t.title,
          t.description,
          t.notes ?? '',
          t.assignedToName ?? '',
          t.assignedToEmail ?? '',
          t.deviceName ?? '',
          t.deviceCode ?? '',
          t.locationName ?? '',
          t.status,
          t.priority,
          loc?.cluster ?? '',
          loc?.building ?? '',
        ].join(' ').toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        return (b.completedAt ?? b.dueDate ?? b.createdAt)
            .compareTo(a.completedAt ?? a.dueDate ?? a.createdAt);
      });
  }

  void _openTaskSheet(BuildContext context, WidgetRef ref, TaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskInspectionSheet(
        task: task,
        isViewer: isViewer,
        onRefresh: onRefresh,
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final bool isAr;
  final int index;
  final VoidCallback onTap;

  const _TaskCard({
    required this.task,
    required this.isAr,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = task.status.toUpperCase();
    final urgent = task.isUrgent || task.isEmergency || task.priority.toUpperCase() == 'URGENT';
    final color = urgent
        ? const Color(0xFFDC2626)
        : s == 'COMPLETED'
            ? const Color(0xFF16A34A)
            : s == 'IN_PROGRESS'
                ? const Color(0xFF0284C7)
                : s == 'OVERDUE'
                    ? const Color(0xFFEA580C)
                    : const Color(0xFF1A237E);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.18), width: urgent ? 1.4 : 1),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 124,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
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
                              task.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _Pill(text: isAr ? task.statusAr : task.statusEn, color: color),
                        ],
                      ),
                      if (task.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _MiniInfo(icon: Icons.person_rounded, text: task.assignedToName ?? (isAr ? 'بدون فني' : 'Unassigned')),
                          if (task.deviceName != null) _MiniInfo(icon: Icons.devices_rounded, text: task.deviceName!),
                          if (task.deviceCode != null) _MiniInfo(icon: Icons.qr_code_rounded, text: task.deviceCode!),
                          if (task.locationName != null) _MiniInfo(icon: Icons.place_rounded, text: task.locationName!),
                          _Pill(text: isAr ? task.priorityAr : task.priority, color: urgent ? const Color(0xFFDC2626) : const Color(0xFF475569)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            task.completedAt != null
                                ? '${isAr ? 'اكتملت' : 'Completed'}: ${_date(task.completedAt!)}'
                                : task.dueDate != null
                                    ? '${isAr ? 'الموعد' : 'Due'}: ${_date(task.dueDate!)}'
                                    : '${isAr ? 'أنشئت' : 'Created'}: ${_date(task.createdAt)}',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            isAr ? 'تفاصيل + فحص' : 'Details + Inspection',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10.5,
                              color: color,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: (index * 25).clamp(0, 250))).fadeIn(duration: 220.ms).slideY(begin: 0.03);
  }
}

class _InspectionList extends ConsumerWidget {
  final List<InspectionDetail> inspections;
  final String search;
  final String? filterCluster;
  final String? filterBuilding;
  final VoidCallback onRefresh;

  const _InspectionList({
    required this.inspections,
    required this.search,
    required this.filterCluster,
    required this.filterBuilding,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = AppLocalizations.of(context).isAr;
    final locations = ref.watch(locationsProvider).valueOrNull ?? [];
    final filtered = _filter(inspections, locations);

    if (filtered.isEmpty) {
      return _EmptyTasks(
        isAr: isAr,
        status: 'INSPECTIONS',
        customText: isAr ? 'لا توجد تفتيشات تمت' : 'No inspections found',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final inspection = filtered[i];
          return _InspectionCard(
            inspection: inspection,
            isAr: isAr,
            index: i,
            onTap: () => _openInspectionSheet(context, inspection),
          );
        },
      ),
    );
  }

  List<InspectionDetail> _filter(
    List<InspectionDetail> list,
    List<LocationModel> locations,
  ) {
    final q = search.trim().toLowerCase();

    return list.where((i) {
      if (filterCluster != null || filterBuilding != null) {
        final matchLocation = locations.firstWhereOrNull((l) {
          final text = '${i.locationText} ${i.deviceName} ${i.deviceCode}'.toLowerCase();
          final name = '${l.name} ${l.cluster ?? ''} ${l.building ?? ''}'.toLowerCase();
          return text.contains(l.name.toLowerCase()) || name.contains(i.locationText.toLowerCase());
        });

        if (filterCluster != null && matchLocation?.cluster != filterCluster) return false;
        if (filterBuilding != null && matchLocation?.building != filterBuilding) return false;
      }

      if (q.isNotEmpty) {
        final haystack = [
          i.reportNumber,
          i.deviceName,
          i.deviceCode,
          i.technicianName,
          i.locationText,
          i.inspectionStatus,
          i.statusAr,
          i.notes ?? '',
          i.issueReason ?? '',
        ].join(' ').toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.inspectedAt.compareTo(a.inspectedAt));
  }

  void _openInspectionSheet(BuildContext context, InspectionDetail inspection) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InspectionDetailSheet(inspection: inspection),
    );
  }
}

class _InspectionCard extends StatelessWidget {
  final InspectionDetail inspection;
  final bool isAr;
  final int index;
  final VoidCallback onTap;

  const _InspectionCard({
    required this.inspection,
    required this.isAr,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _inspectionColor(inspection.inspectionStatus);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 120,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
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
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _Pill(text: isAr ? inspection.statusAr : inspection.inspectionStatus, color: color),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _MiniInfo(icon: Icons.confirmation_number_rounded, text: inspection.reportNumber),
                          _MiniInfo(icon: Icons.person_rounded, text: inspection.technicianName),
                          _MiniInfo(icon: Icons.qr_code_rounded, text: inspection.deviceCode),
                          if (inspection.locationText.trim().isNotEmpty)
                            _MiniInfo(icon: Icons.place_rounded, text: inspection.locationText),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Icon(Icons.event_available_rounded, size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            '${isAr ? 'تم التفتيش' : 'Inspected'}: ${_dateTime(inspection.inspectedAt)}',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          if (inspection.imageUrl != null && inspection.imageUrl!.trim().isNotEmpty)
                            Icon(Icons.image_rounded, size: 17, color: color),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: (index * 25).clamp(0, 250))).fadeIn(duration: 220.ms).slideY(begin: 0.03);
  }
}

class _TaskInspectionSheet extends ConsumerWidget {
  final TaskModel task;
  final bool isViewer;
  final VoidCallback onRefresh;

  const _TaskInspectionSheet({
    required this.task,
    required this.isViewer,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = AppLocalizations.of(context).isAr;
    final inspectionsAsync = ref.watch(
      adminInspectionsProvider(
        AdminInspectionFilter(deviceId: task.deviceId),
      ),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.84,
      maxChildSize: 0.96,
      minChildSize: 0.50,
      builder: (_, ctrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: ListView(
            controller: ctrl,
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
              _TaskStatusHero(task: task),
              const SizedBox(height: 14),
              _DetailBlock(
                title: isAr ? 'تفاصيل المهمة' : 'Task Details',
                icon: Icons.assignment_rounded,
                children: [
                  _InfoRow(label: isAr ? 'العنوان' : 'Title', value: task.title),
                  _InfoRow(label: isAr ? 'الحالة' : 'Status', value: isAr ? task.statusAr : task.statusEn),
                  _InfoRow(label: isAr ? 'الأولوية' : 'Priority', value: isAr ? task.priorityAr : task.priority),
                  _InfoRow(label: isAr ? 'أُرسلت إلى' : 'Assigned to', value: task.assignedToName ?? (isAr ? 'غير محدد' : 'Unassigned')),
                  if (task.assignedToEmail != null)
                    _InfoRow(label: isAr ? 'إيميل الفني' : 'Technician Email', value: task.assignedToEmail!),
                  _InfoRow(label: isAr ? 'الجهاز' : 'Device', value: task.deviceName ?? '-'),
                  _InfoRow(label: isAr ? 'كود الجهاز' : 'Device Code', value: task.deviceCode ?? '-'),
                  _InfoRow(label: isAr ? 'الموقع' : 'Location', value: task.locationName ?? '-'),
                  _InfoRow(label: isAr ? 'تاريخ الإنشاء' : 'Created', value: _dateTime(task.createdAt)),
                  if (task.dueDate != null)
                    _InfoRow(label: isAr ? 'موعد التنفيذ' : 'Due Date', value: _dateTime(task.dueDate!)),
                  if (task.completedAt != null)
                    _InfoRow(label: isAr ? 'تاريخ الإكمال' : 'Completed At', value: _dateTime(task.completedAt!)),
                  if (task.description.trim().isNotEmpty)
                    _InfoRow(label: isAr ? 'الوصف' : 'Description', value: task.description),
                  if ((task.notes ?? '').trim().isNotEmpty)
                    _InfoRow(label: isAr ? 'ملاحظات' : 'Notes', value: task.notes!),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                isAr ? 'هل تم الفحص؟' : 'Was it inspected?',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              inspectionsAsync.when(
                loading: () => const _SmallLoadingCard(),
                error: (e, _) => _InlineError(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(
                    adminInspectionsProvider(AdminInspectionFilter(deviceId: task.deviceId)),
                  ),
                ),
                data: (items) {
                  final related = _relatedInspections(task, items);
                  if (related.isEmpty) {
                    return _NoInspectionBox(isAr: isAr);
                  }

                  return Column(
                    children: [
                      _InspectionDoneBox(
                        isAr: isAr,
                        count: related.length,
                        last: related.first,
                      ),
                      const SizedBox(height: 10),
                      ...related.map((inspection) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _LinkedInspectionTile(
                            inspection: inspection,
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => _InspectionDetailSheet(inspection: inspection),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
              if (!isViewer) ...[
                const SizedBox(height: 14),
                _TaskActions(
                  task: task,
                  onRefresh: onRefresh,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TaskStatusHero extends StatelessWidget {
  final TaskModel task;

  const _TaskStatusHero({required this.task});

  @override
  Widget build(BuildContext context) {
    final isAr = AppLocalizations.of(context).isAr;
    final color = _taskColor(task);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(_taskIcon(task), color: color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? task.statusAr : task.statusEn,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  isAr
                      ? 'تم إرسال المهمة إلى: ${task.assignedToName ?? 'فني غير محدد'}'
                      : 'Assigned to: ${task.assignedToName ?? 'Unassigned technician'}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w700,
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

class _TaskActions extends ConsumerWidget {
  final TaskModel task;
  final VoidCallback onRefresh;

  const _TaskActions({
    required this.task,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = AppLocalizations.of(context).isAr;

    return _DetailBlock(
      title: isAr ? 'تغيير حالة المهمة' : 'Change Task Status',
      icon: Icons.edit_note_rounded,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ActionChipButton(
              label: isAr ? 'معلقة' : 'Pending',
              color: const Color(0xFFF59E0B),
              onTap: () => _update(context, ref, 'PENDING'),
            ),
            _ActionChipButton(
              label: isAr ? 'جارية' : 'In Progress',
              color: const Color(0xFF0284C7),
              onTap: () => _update(context, ref, 'IN_PROGRESS'),
            ),
            _ActionChipButton(
              label: isAr ? 'مكتملة' : 'Completed',
              color: const Color(0xFF16A34A),
              onTap: () => _update(context, ref, 'COMPLETED'),
            ),
            _ActionChipButton(
              label: isAr ? 'متأخرة' : 'Overdue',
              color: const Color(0xFFEA580C),
              onTap: () => _update(context, ref, 'OVERDUE'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _update(BuildContext context, WidgetRef ref, String status) async {
    await ref.read(adminRepoProvider).updateTask(task.id, {'status': status});
    onRefresh();
    if (context.mounted) Navigator.pop(context);
  }
}

class _ActionChipButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChipButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _InspectionDoneBox extends StatelessWidget {
  final bool isAr;
  final int count;
  final InspectionDetail last;

  const _InspectionDoneBox({
    required this.isAr,
    required this.count,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    final color = _inspectionColor(last.inspectionStatus);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_rounded, color: color, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isAr
                  ? 'تم الفحص: يوجد $count تقرير تفتيش مرتبط. آخر حالة: ${last.statusAr}'
                  : 'Inspected: $count linked inspection report(s). Last status: ${last.inspectionStatus}',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoInspectionBox extends StatelessWidget {
  final bool isAr;

  const _NoInspectionBox({required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.pending_actions_rounded, color: Color(0xFFF59E0B), size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isAr
                  ? 'لسه مفيش تفتيش متسجل على هذه المهمة/الجهاز من الباك إند.'
                  : 'No backend inspection has been recorded for this task/device yet.',
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkedInspectionTile extends StatelessWidget {
  final InspectionDetail inspection;
  final VoidCallback onTap;

  const _LinkedInspectionTile({
    required this.inspection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _inspectionColor(inspection.inspectionStatus);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.10),
                child: Icon(Icons.fact_check_rounded, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${inspection.reportNumber} • ${inspection.statusAr}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                      ),
                    ),
                    Text(
                      '${inspection.technicianName} — ${_dateTime(inspection.inspectedAt)}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InspectionDetailSheet extends StatelessWidget {
  final InspectionDetail inspection;

  const _InspectionDetailSheet({required this.inspection});

  @override
  Widget build(BuildContext context) {
    final isAr = AppLocalizations.of(context).isAr;
    final color = _inspectionColor(inspection.inspectionStatus);

    return DraggableScrollableSheet(
      initialChildSize: 0.76,
      maxChildSize: 0.95,
      minChildSize: 0.45,
      builder: (_, ctrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: ListView(
            controller: ctrl,
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
                    Icon(Icons.fact_check_rounded, color: color, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inspection.deviceName,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            '${inspection.reportNumber} • ${inspection.statusAr}',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: color,
                              fontWeight: FontWeight.w800,
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
                title: isAr ? 'تفاصيل التفتيش' : 'Inspection Details',
                icon: Icons.assignment_turned_in_rounded,
                children: [
                  _InfoRow(label: isAr ? 'رقم التقرير' : 'Report', value: inspection.reportNumber),
                  _InfoRow(label: isAr ? 'الحالة' : 'Status', value: isAr ? inspection.statusAr : inspection.inspectionStatus),
                  _InfoRow(label: isAr ? 'الفني' : 'Technician', value: inspection.technicianName),
                  _InfoRow(label: isAr ? 'الجهاز' : 'Device', value: inspection.deviceName),
                  _InfoRow(label: isAr ? 'كود الجهاز' : 'Device Code', value: inspection.deviceCode),
                  _InfoRow(label: isAr ? 'الموقع' : 'Location', value: inspection.locationText),
                  _InfoRow(label: isAr ? 'التاريخ' : 'Date', value: _dateTime(inspection.inspectedAt)),
                  _InfoRow(label: 'GPS', value: '${inspection.latitude.toStringAsFixed(4)}, ${inspection.longitude.toStringAsFixed(4)}'),
                  if ((inspection.issueReason ?? '').trim().isNotEmpty)
                    _InfoRow(label: isAr ? 'سبب المشكلة' : 'Issue Reason', value: inspection.issueReason!),
                  if ((inspection.notes ?? '').trim().isNotEmpty)
                    _InfoRow(label: isAr ? 'ملاحظات' : 'Notes', value: inspection.notes!),
                ],
              ),
              if (inspection.imageUrl != null && inspection.imageUrl!.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    inspection.imageUrl!,
                    height: 230,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 140,
                      color: const Color(0xFFF1F5F9),
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_rounded, size: 42, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
              ],
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF1A237E), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
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

  const _InfoRow({required this.label, required this.value});

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
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value.trim().isEmpty ? '-' : value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: Color(0xFF0F172A),
                fontSize: 12,
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

  const _MiniInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF475569)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CreateTaskForm extends ConsumerStatefulWidget {
  final Future<void> Function(CreateTaskRequest) onSubmit;
  final VoidCallback onCancel;

  const CreateTaskForm({
    super.key,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  ConsumerState<CreateTaskForm> createState() => _CreateTaskFormState();
}

class _CreateTaskFormState extends ConsumerState<CreateTaskForm> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _notes = TextEditingController();

  String _priority = 'MEDIUM';
  bool _isEmergency = false;
  String? _techId;
  String? _deviceId;
  String? _locationId;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 3));
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = AppLocalizations.of(context).isAr;
    final techs = ref.watch(activeTechniciansProvider).valueOrNull ?? [];
    final devices = ref.watch(adminDevicesProvider(null)).valueOrNull ?? [];
    final locations = ref.watch(locationsProvider).valueOrNull ?? [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'إنشاء مهمة جديدة' : 'Create New Task',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _isEmergency,
            onChanged: (v) => setState(() {
              _isEmergency = v;
              if (v) _priority = 'URGENT';
            }),
            title: Text(
              isAr ? 'مهمة طارئة' : 'Emergency task',
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
            ),
            activeColor: const Color(0xFFDC2626),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: _isEmergency ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
          ),
          const SizedBox(height: 10),
          _TextInput(controller: _title, label: isAr ? 'عنوان المهمة *' : 'Task title *', icon: Icons.title_rounded),
          const SizedBox(height: 10),
          _TextInput(controller: _desc, label: isAr ? 'الوصف' : 'Description', icon: Icons.description_rounded, maxLines: 2),
          const SizedBox(height: 10),
          _Drop<String>(
            value: techs.any((e) => e.id == _techId) ? _techId : null,
            hint: isAr ? 'اختاري فني نشط *' : 'Select active technician *',
            items: techs.map((t) => _DropItem(t.id, '${t.fullName} — ${t.username}')).toList(),
            onChanged: (v) => setState(() => _techId = v),
          ),
          const SizedBox(height: 10),
          _Drop<String>(
            value: devices.any((e) => e.id == _deviceId) ? _deviceId : null,
            hint: isAr ? 'الجهاز' : 'Device',
            items: devices.map((d) => _DropItem(d.id, '${d.name} (${d.deviceCode})')).toList(),
            onChanged: (v) {
              final device = devices.firstWhereOrNull((d) => d.id == v);
              setState(() {
                _deviceId = v;
                if (device?.locationId != null) _locationId = device!.locationId;
              });
            },
          ),
          const SizedBox(height: 10),
          _Drop<String>(
            value: locations.any((e) => e.id == _locationId) ? _locationId : null,
            hint: isAr ? 'الموقع' : 'Location',
            items: locations.map((loc) => _DropItem(loc.id, loc.name)).toList(),
            onChanged: (v) => setState(() => _locationId = v),
          ),
          const SizedBox(height: 10),
          _Drop<String>(
            value: _priority,
            hint: isAr ? 'الأولوية' : 'Priority',
            items: [
              _DropItem('LOW', isAr ? 'منخفضة' : 'Low'),
              _DropItem('MEDIUM', isAr ? 'متوسطة' : 'Medium'),
              _DropItem('HIGH', isAr ? 'عالية' : 'High'),
              _DropItem('URGENT', isAr ? 'طارئة' : 'Urgent'),
            ],
            onChanged: (v) => setState(() {
              _priority = v ?? 'MEDIUM';
              if (_priority == 'URGENT') _isEmergency = true;
            }),
          ),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dueDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _dueDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF1A237E)),
                  const SizedBox(width: 10),
                  Text(
                    '${isAr ? 'موعد التنفيذ' : 'Due date'}: ${_date(_dueDate)}',
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _TextInput(controller: _notes, label: isAr ? 'ملاحظات' : 'Notes', icon: Icons.notes_rounded, maxLines: 2),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: widget.onCancel, child: Text(isAr ? 'إلغاء' : 'Cancel'))),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _loading || _title.text.trim().isEmpty || _techId == null ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEmergency ? const Color(0xFFDC2626) : const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isAr ? 'إنشاء المهمة' : 'Create Task'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await widget.onSubmit(
        CreateTaskRequest(
          title: _title.text.trim(),
          description: _desc.text.trim(),
          assignedToId: _techId!,
          deviceId: _deviceId,
          locationId: _locationId,
          priority: _isEmergency ? 'URGENT' : _priority,
          isEmergency: _isEmergency,
          dueDate: _dueDate,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;

  const _TextInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _DropItem<T> {
  final T value;
  final String label;
  const _DropItem(this.value, this.label);
}

class _Drop<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<_DropItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _Drop({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          value: value,
          hint: Text(hint, overflow: TextOverflow.ellipsis),
          isExpanded: true,
          items: [
            DropdownMenuItem<T?>(value: null, child: Text(hint, overflow: TextOverflow.ellipsis)),
            ...items.map((e) {
              return DropdownMenuItem<T?>(
                value: e.value,
                child: Text(e.label, overflow: TextOverflow.ellipsis),
              );
            }),
          ],
          onChanged: onChanged,
        ),
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
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(999)),
      child: Text(
        text,
        style: TextStyle(color: color, fontFamily: 'Cairo', fontSize: 10.5, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _IconButtonLite extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final int badge;

  const _IconButtonLite({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: active ? Colors.white.withOpacity(0.22) : Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          if (badge > 0)
            Positioned(
              top: -4,
              right: -4,
              child: CircleAvatar(
                radius: 9,
                backgroundColor: const Color(0xFFF59E0B),
                child: Text(
                  '$badge',
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();
  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          height: 118,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 900.ms),
      );
}

class _SmallLoadingCard extends StatelessWidget {
  const _SmallLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 900.ms);
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFDC2626))),
          TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  final bool isAr;
  final String status;
  final String? customText;

  const _EmptyTasks({
    required this.isAr,
    required this.status,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_rounded, size: 58, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 10),
          Text(
            customText ?? (isAr ? 'لا توجد مهام في هذا القسم' : 'No tasks in this tab'),
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 44),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFDC2626))),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _InspectionStatusOption {
  final String value;
  final String ar;
  final String en;
  const _InspectionStatusOption(this.value, this.ar, this.en);
}

const _inspectionStatuses = [
  _InspectionStatusOption('OK', 'سليم', 'OK'),
  _InspectionStatusOption('NOT_OK', 'غير سليم', 'Not OK'),
  _InspectionStatusOption('PARTIAL', 'جزئي', 'Partial'),
  _InspectionStatusOption('NOT_REACHABLE', 'غير متاح', 'Not reachable'),
];

String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String _dateTime(DateTime d) => '${_date(d)}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

Color _inspectionColor(String status) {
  switch (status.toUpperCase()) {
    case 'OK':
      return const Color(0xFF16A34A);
    case 'NOT_OK':
      return const Color(0xFFDC2626);
    case 'PARTIAL':
      return const Color(0xFFF59E0B);
    case 'NOT_REACHABLE':
      return const Color(0xFF64748B);
    default:
      return const Color(0xFF0284C7);
  }
}

Color _taskColor(TaskModel task) {
  final s = task.status.toUpperCase();
  final urgent = task.isUrgent || task.isEmergency || task.priority.toUpperCase() == 'URGENT';
  if (urgent) return const Color(0xFFDC2626);
  if (s == 'COMPLETED') return const Color(0xFF16A34A);
  if (s == 'IN_PROGRESS') return const Color(0xFF0284C7);
  if (s == 'OVERDUE') return const Color(0xFFEA580C);
  return const Color(0xFF1A237E);
}

IconData _taskIcon(TaskModel task) {
  final s = task.status.toUpperCase();
  final urgent = task.isUrgent || task.isEmergency || task.priority.toUpperCase() == 'URGENT';
  if (urgent) return Icons.bolt_rounded;
  if (s == 'COMPLETED') return Icons.check_circle_rounded;
  if (s == 'IN_PROGRESS') return Icons.play_circle_rounded;
  if (s == 'OVERDUE') return Icons.timer_off_rounded;
  return Icons.hourglass_empty_rounded;
}

List<InspectionDetail> _relatedInspections(TaskModel task, List<InspectionDetail> source) {
  final deviceCode = (task.deviceCode ?? '').trim().toLowerCase();
  final deviceName = (task.deviceName ?? '').trim().toLowerCase();
  final techName = (task.assignedToName ?? '').trim().toLowerCase();

  final result = source.where((i) {
    final iCode = i.deviceCode.trim().toLowerCase();
    final iDevice = i.deviceName.trim().toLowerCase();
    final iTech = i.technicianName.trim().toLowerCase();

    final sameDeviceCode = deviceCode.isNotEmpty && iCode == deviceCode;
    final sameDeviceName = deviceName.isNotEmpty && iDevice == deviceName;
    final sameTech = techName.isNotEmpty && iTech == techName;

    if (sameDeviceCode || sameDeviceName) return true;
    if (sameTech && (sameDeviceCode || sameDeviceName)) return true;
    return false;
  }).toList()
    ..sort((a, b) => b.inspectedAt.compareTo(a.inspectedAt));

  return result;
}

extension _FirstWhereOrNullX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T item) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}
