// lib/admin/admin_providers.dart

import 'package:access_track/admin/admin_models.dart';
import 'package:access_track/admin/admin_repository.dart';
import 'package:access_track/core/api/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ════════════════════════════════════════════════════════
//  GLOBAL FILTER
// ════════════════════════════════════════════════════════

class GlobalAdminFilter {
  final String dateRange; // ALL, TODAY, WEEK, MONTH
  final String deviceStatus; // ALL, OK, NEEDS_MAINTENANCE, OUT_OF_SERVICE
  final String taskStatus; // ALL, PENDING, IN_PROGRESS, COMPLETED, OVERDUE
  final String cluster;
  final String building;

  const GlobalAdminFilter({
    this.dateRange = 'ALL',
    this.deviceStatus = 'ALL',
    this.taskStatus = 'ALL',
    this.cluster = 'ALL',
    this.building = 'ALL',
  });

  GlobalAdminFilter copyWith({
    String? dateRange,
    String? deviceStatus,
    String? taskStatus,
    String? cluster,
    String? building,
  }) {
    return GlobalAdminFilter(
      dateRange: dateRange ?? this.dateRange,
      deviceStatus: deviceStatus ?? this.deviceStatus,
      taskStatus: taskStatus ?? this.taskStatus,
      cluster: cluster ?? this.cluster,
      building: building ?? this.building,
    );
  }
}

final adminGlobalFilterProvider =
    StateProvider<GlobalAdminFilter>((ref) => const GlobalAdminFilter());

final adminPageIndexProvider = StateProvider<int>((ref) => 0);

final adminRepoProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.read(apiDioProvider)),
);

// ════════════════════════════════════════════════════════
//  TASKS PROVIDERS
// ════════════════════════════════════════════════════════

final allTasksProvider = FutureProvider.autoDispose<List<TaskModel>>(
  (ref) => ref.read(adminRepoProvider).getTasks(),
);

final tasksByStatusProvider =
    FutureProvider.autoDispose.family<List<TaskModel>, String>(
  (ref, status) {
    if (status.toUpperCase() == 'URGENT') {
      return ref.read(adminRepoProvider).getUrgentTasks();
    }

    return ref.read(adminRepoProvider).getTasks(status: status);
  },
);

final urgentTasksProvider = FutureProvider.autoDispose<List<TaskModel>>(
  (ref) => ref.read(adminRepoProvider).getUrgentTasks(),
);

final tasksByTechnicianProvider =
    FutureProvider.autoDispose.family<List<TaskModel>, String>(
  (ref, techId) => ref.read(adminRepoProvider).getTasks(assignedToId: techId),
);

final tasksByDeviceProvider =
    FutureProvider.autoDispose.family<List<TaskModel>, String>(
  (ref, deviceId) => ref.read(adminRepoProvider).getTasks(deviceId: deviceId),
);

// ════════════════════════════════════════════════════════
//  TECHNICIANS PROVIDERS
// ════════════════════════════════════════════════════════

final techniciansProvider = FutureProvider.autoDispose<List<TechnicianModel>>(
  (ref) => ref.read(adminRepoProvider).getTechnicians(),
);

final activeTechniciansProvider =
    FutureProvider.autoDispose<List<TechnicianModel>>(
  (ref) => ref.read(adminRepoProvider).getTechnicians(activeOnly: true),
);

final technicianByIdProvider =
    FutureProvider.autoDispose.family<TechnicianModel, String>(
  (ref, id) => ref.read(adminRepoProvider).getTechnicianById(id),
);

final techActivityProvider =
    FutureProvider.autoDispose.family<List<InspectionDetail>, String>(
  (ref, techId) => ref.read(adminRepoProvider).getTechnicianActivity(techId),
);

// ════════════════════════════════════════════════════════
//  DEVICES PROVIDERS
// ════════════════════════════════════════════════════════

final adminDevicesProvider =
    FutureProvider.autoDispose.family<List<AdminDeviceModel>, String?>(
  (ref, status) => ref.read(adminRepoProvider).getDevices(status: status),
);

final deviceHistoryProvider =
    FutureProvider.autoDispose.family<List<DeviceHistoryItem>, String>(
  (ref, deviceId) => ref.read(adminRepoProvider).getDeviceHistory(deviceId),
);

final deviceByIdProvider =
    FutureProvider.autoDispose.family<AdminDeviceModel, String>(
  (ref, id) => ref.read(adminRepoProvider).getDeviceById(id),
);

// ════════════════════════════════════════════════════════
//  INSPECTIONS PROVIDERS
// ════════════════════════════════════════════════════════

class AdminInspectionFilter {
  final String? technicianId;
  final String? locationId;
  final String? deviceId;
  final String? status;
  final DateTime? from;
  final DateTime? to;

  const AdminInspectionFilter({
    this.technicianId,
    this.locationId,
    this.deviceId,
    this.status,
    this.from,
    this.to,
  });

  @override
  bool operator ==(Object other) {
    return other is AdminInspectionFilter &&
        technicianId == other.technicianId &&
        locationId == other.locationId &&
        deviceId == other.deviceId &&
        status == other.status &&
        from == other.from &&
        to == other.to;
  }

  @override
  int get hashCode {
    return Object.hash(
      technicianId,
      locationId,
      deviceId,
      status,
      from,
      to,
    );
  }
}

final adminInspectionsProvider = FutureProvider.autoDispose
    .family<List<InspectionDetail>, AdminInspectionFilter>(
  (ref, filter) {
    return ref.read(adminRepoProvider).getInspections(
          technicianId: filter.technicianId,
          locationId: filter.locationId,
          deviceId: filter.deviceId,
          status: filter.status,
          from: filter.from,
          to: filter.to,
          limit: 500,
        );
  },
);

final monthlyInspectionsProvider =
    FutureProvider.autoDispose<List<InspectionDetail>>(
  (ref) {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month + 1, 1);

    return ref.read(adminRepoProvider).getInspections(
          from: from,
          to: to,
          limit: 1000,
        );
  },
);

// ════════════════════════════════════════════════════════
//  LOCATIONS PROVIDER
// ════════════════════════════════════════════════════════

final locationsProvider = FutureProvider.autoDispose<List<LocationModel>>(
  (ref) => ref.read(adminRepoProvider).getLocations(),
);

// ════════════════════════════════════════════════════════
//  RAW BACKEND CHARTS
// ════════════════════════════════════════════════════════

final tasksChartProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) => ref.read(adminRepoProvider).getTasksChart(),
);

final devicesChartProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) => ref.read(adminRepoProvider).getDevicesChart(),
);

final inspChartProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) => ref.read(adminRepoProvider).getInspectionsChart(),
);

// ════════════════════════════════════════════════════════
//  ADMIN STATS FROM BACKEND + FALLBACK CALCULATION
// ════════════════════════════════════════════════════════

final adminStatsProvider = FutureProvider.autoDispose<AdminStats>((ref) async {
  final filter = ref.watch(adminGlobalFilterProvider);
  final repo = ref.read(adminRepoProvider);

  if (filter.dateRange == 'ALL' &&
      filter.deviceStatus == 'ALL' &&
      filter.taskStatus == 'ALL' &&
      filter.cluster == 'ALL' &&
      filter.building == 'ALL') {
    try {
      final backendStats = await repo.getAdminStats();

      final hasUsefulData = backendStats.totalDevices > 0 ||
          backendStats.totalTasks > 0 ||
          backendStats.totalTechnicians > 0 ||
          backendStats.totalInspectionsMonth > 0;

      if (hasUsefulData) return backendStats;
    } catch (_) {
      // fallback below
    }
  }

  var tasks = await ref.watch(allTasksProvider.future);
  final technicians = await ref.watch(techniciansProvider.future);
  var devices = await ref.watch(adminDevicesProvider(null).future);
  var inspections = await ref.watch(monthlyInspectionsProvider.future);
  var locations = await ref.watch(locationsProvider.future);

  tasks = _filterTasks(tasks, filter);
  devices = _filterDevices(devices, filter);
  inspections = _filterInspections(inspections, filter);

  if (filter.cluster != 'ALL' || filter.building != 'ALL') {
    final allowedLocationIds = devices
        .map((d) => d.locationId)
        .whereType<String>()
        .where((id) => id.trim().isNotEmpty)
        .toSet();

    locations = locations.where((l) {
      if (filter.cluster != 'ALL' && l.cluster != filter.cluster) {
        return false;
      }

      if (filter.building != 'ALL' && l.building != filter.building) {
        return false;
      }

      if (allowedLocationIds.isEmpty) return true;
      return allowedLocationIds.contains(l.id);
    }).toList();
  }

  final now = DateTime.now();

  final todayInspections = inspections.where((i) {
    return i.inspectedAt.year == now.year &&
        i.inspectedAt.month == now.month &&
        i.inspectedAt.day == now.day;
  }).length;

  final completedTasks =
      tasks.where((t) => t.status.toUpperCase() == 'COMPLETED').length;

  final pendingTasks =
      tasks.where((t) => t.status.toUpperCase() == 'PENDING').length;

  final inProgressTasks =
      tasks.where((t) => t.status.toUpperCase() == 'IN_PROGRESS').length;

  final overdueTasks =
      tasks.where((t) => t.status.toUpperCase() == 'OVERDUE').length;

  final urgentTasks = tasks.where((t) {
    return t.isUrgent ||
        t.isEmergency ||
        t.priority.toUpperCase() == 'URGENT' ||
        t.status.toUpperCase() == 'URGENT';
  }).length;

  final okDevices = devices.where((d) {
    return d.currentStatus.toUpperCase() == 'OK';
  }).length;

  final maintenanceDevices = devices.where((d) {
    final s = d.currentStatus.toUpperCase();
    return s == 'NEEDS_MAINTENANCE' ||
        s == 'UNDER_MAINTENANCE' ||
        s == 'PARTIAL';
  }).length;

  final outOfServiceDevices = devices.where((d) {
    final s = d.currentStatus.toUpperCase();
    return s == 'OUT_OF_SERVICE' ||
        s == 'NOT_OK' ||
        s == 'NOT_REACHABLE';
  }).length;

  final activeTechnicians = technicians.where((t) {
    return t.isActive || t.status.toUpperCase() == 'ACTIVE';
  }).length;

  return AdminStats(
    totalTechnicians: technicians.length,
    activeTechnicians: activeTechnicians,
    totalTasks: tasks.length,
    completedTasks: completedTasks,
    pendingTasks: pendingTasks,
    urgentTasks: urgentTasks,
    inProgressTasks: inProgressTasks,
    overdueTasks: overdueTasks,
    totalDevices: devices.length,
    okDevices: okDevices,
    maintenanceDevices: maintenanceDevices,
    outOfServiceDevices: outOfServiceDevices,
    totalInspectionsToday: todayInspections,
    totalInspectionsMonth: inspections.length,
    openReports: maintenanceDevices + outOfServiceDevices,
    totalLocations: locations.length,
  );
});

// ════════════════════════════════════════════════════════
//  ADMIN ANALYTICS
// ════════════════════════════════════════════════════════

final adminAnalyticsProvider =
    FutureProvider.autoDispose<AdminAnalyticsData>((ref) async {
  final filter = ref.watch(adminGlobalFilterProvider);
  final stats = await ref.watch(adminStatsProvider.future);

  var tasks = await ref.watch(allTasksProvider.future);
  final technicians = await ref.watch(techniciansProvider.future);
  var devices = await ref.watch(adminDevicesProvider(null).future);
  var inspections = await ref.watch(monthlyInspectionsProvider.future);

  tasks = _filterTasks(tasks, filter);
  devices = _filterDevices(devices, filter);
  inspections = _filterInspections(inspections, filter);

  return AdminAnalyticsData(
    stats: stats,
    deviceStatus: [
      AnalyticsLegendItem(label: 'OK', value: stats.okDevices),
      AnalyticsLegendItem(label: 'MAINTENANCE', value: stats.maintenanceDevices),
      AnalyticsLegendItem(label: 'OUT_OF_SERVICE', value: stats.outOfServiceDevices),
    ],
    taskStatus: [
      AnalyticsLegendItem(label: 'PENDING', value: stats.pendingTasks),
      AnalyticsLegendItem(label: 'IN_PROGRESS', value: stats.inProgressTasks),
      AnalyticsLegendItem(label: 'COMPLETED', value: stats.completedTasks),
      AnalyticsLegendItem(label: 'OVERDUE', value: stats.overdueTasks),
    ],
    devicesByBuilding: _groupDevicesByBuilding(devices),
    devicesByType: _groupDevicesByType(devices),
    taskCompletionTrend: _buildTaskCompletionTrend(tasks),
    technicianPerformance: _buildTechnicianPerformance(
      technicians,
      tasks,
      inspections,
    ),
    inspectionsOverTime: _buildInspectionTrend(inspections),
    taskExecutionByTechnician: _buildTaskExecutionByTechnician(
      technicians,
      tasks,
    ),
  );
});

// ════════════════════════════════════════════════════════
//  FILTER HELPERS
// ════════════════════════════════════════════════════════

List<TaskModel> _filterTasks(
  List<TaskModel> tasks,
  GlobalAdminFilter filter,
) {
  var result = [...tasks];

  final cutoff = _cutoffDate(filter.dateRange);

  if (cutoff != null) {
    result = result.where((t) {
      return t.createdAt.isAfter(cutoff) || _sameDay(t.createdAt, cutoff);
    }).toList();
  }

  if (filter.taskStatus != 'ALL') {
    result = result.where((t) {
      if (filter.taskStatus == 'URGENT') {
        return t.isUrgent || t.priority.toUpperCase() == 'URGENT';
      }

      return t.status.toUpperCase() == filter.taskStatus.toUpperCase();
    }).toList();
  }

  return result;
}

List<AdminDeviceModel> _filterDevices(
  List<AdminDeviceModel> devices,
  GlobalAdminFilter filter,
) {
  var result = [...devices];

  if (filter.deviceStatus != 'ALL') {
    result = result.where((d) {
      final s = d.currentStatus.toUpperCase();
      final wanted = filter.deviceStatus.toUpperCase();

      if (wanted == 'NEEDS_MAINTENANCE') {
        return s == 'NEEDS_MAINTENANCE' ||
            s == 'UNDER_MAINTENANCE' ||
            s == 'PARTIAL';
      }

      if (wanted == 'OUT_OF_SERVICE') {
        return s == 'OUT_OF_SERVICE' ||
            s == 'NOT_OK' ||
            s == 'NOT_REACHABLE';
      }

      return s == wanted;
    }).toList();
  }

  if (filter.cluster != 'ALL') {
    result = result.where((d) {
      return (d.locationName?.contains(filter.cluster) ?? false) ||
          (d.locationBuilding?.contains(filter.cluster) ?? false);
    }).toList();
  }

  if (filter.building != 'ALL') {
    result = result.where((d) {
      return d.locationBuilding == filter.building ||
          (d.locationName?.contains(filter.building) ?? false);
    }).toList();
  }

  return result;
}

List<InspectionDetail> _filterInspections(
  List<InspectionDetail> inspections,
  GlobalAdminFilter filter,
) {
  var result = [...inspections];

  final cutoff = _cutoffDate(filter.dateRange);

  if (cutoff != null) {
    result = result.where((i) {
      return i.inspectedAt.isAfter(cutoff) || _sameDay(i.inspectedAt, cutoff);
    }).toList();
  }

  return result;
}

DateTime? _cutoffDate(String range) {
  final now = DateTime.now();

  switch (range) {
    case 'TODAY':
      return DateTime(now.year, now.month, now.day);
    case 'WEEK':
      return now.subtract(const Duration(days: 7));
    case 'MONTH':
      return now.subtract(const Duration(days: 30));
    default:
      return null;
  }
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

// ════════════════════════════════════════════════════════
//  ANALYTICS HELPERS
// ════════════════════════════════════════════════════════

List<AnalyticsBarDatum> _groupDevicesByBuilding(
  List<AdminDeviceModel> devices,
) {
  final map = <String, int>{};

  for (final d in devices) {
    final key = (d.locationBuilding ?? d.locationName ?? 'غير محدد').trim();
    if (key.isEmpty) continue;
    map[key] = (map[key] ?? 0) + 1;
  }

  final list = map.entries
      .map((e) => AnalyticsBarDatum(label: e.key, value: e.value.toDouble()))
      .toList();

  list.sort((a, b) => b.value.compareTo(a.value));
  return list.take(8).toList();
}

List<AnalyticsBarDatum> _groupDevicesByType(
  List<AdminDeviceModel> devices,
) {
  final map = <String, int>{};

  for (final d in devices) {
    final key = (d.typeName ?? 'Unknown').trim();
    if (key.isEmpty) continue;
    map[key] = (map[key] ?? 0) + 1;
  }

  final list = map.entries
      .map((e) => AnalyticsBarDatum(label: e.key, value: e.value.toDouble()))
      .toList();

  list.sort((a, b) => b.value.compareTo(a.value));
  return list.take(8).toList();
}

List<AnalyticsLineDatum> _buildTaskCompletionTrend(
  List<TaskModel> tasks,
) {
  final days = _lastSevenDays();

  return days.map((day) {
    final count = tasks.where((t) {
      final completedAt = t.completedAt;
      if (completedAt == null) return false;
      return _sameDay(completedAt, day);
    }).length;

    return AnalyticsLineDatum(
      label: '${day.day}/${day.month}',
      value: count.toDouble(),
    );
  }).toList();
}

List<AnalyticsLineDatum> _buildInspectionTrend(
  List<InspectionDetail> inspections,
) {
  final days = _lastSevenDays();

  return days.map((day) {
    final count = inspections.where((i) {
      return _sameDay(i.inspectedAt, day);
    }).length;

    return AnalyticsLineDatum(
      label: '${day.day}/${day.month}',
      value: count.toDouble(),
    );
  }).toList();
}

List<DateTime> _lastSevenDays() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return List.generate(
    7,
    (i) => today.subtract(Duration(days: 6 - i)),
  );
}

List<AnalyticsBarDatum> _buildTechnicianPerformance(
  List<TechnicianModel> technicians,
  List<TaskModel> tasks,
  List<InspectionDetail> inspections,
) {
  final result = <AnalyticsBarDatum>[];

  for (final tech in technicians) {
    final name = tech.fullName.trim().isEmpty ? tech.username : tech.fullName;

    final completedTasks = tasks.where((t) {
      return t.assignedToId == tech.id &&
          t.status.toUpperCase() == 'COMPLETED';
    }).length;

    final inspectionCount = inspections.where((i) {
      return i.technicianName.trim().toLowerCase() ==
          name.trim().toLowerCase();
    }).length;

    final score = completedTasks + inspectionCount;

    result.add(
      AnalyticsBarDatum(
        label: _shortName(name),
        value: score.toDouble(),
      ),
    );
  }

  result.sort((a, b) => b.value.compareTo(a.value));
  return result.take(8).toList();
}

List<AnalyticsStackedDatum> _buildTaskExecutionByTechnician(
  List<TechnicianModel> technicians,
  List<TaskModel> tasks,
) {
  final result = <AnalyticsStackedDatum>[];

  for (final tech in technicians) {
    final name = tech.fullName.trim().isEmpty ? tech.username : tech.fullName;

    final techTasks = tasks.where((t) => t.assignedToId == tech.id).toList();

    final completed = techTasks.where((t) {
      return t.status.toUpperCase() == 'COMPLETED';
    }).length;

    final inProgress = techTasks.where((t) {
      return t.status.toUpperCase() == 'IN_PROGRESS';
    }).length;

    final pending = techTasks.where((t) {
      final s = t.status.toUpperCase();
      return s == 'PENDING' || s == 'OVERDUE';
    }).length;

    result.add(
      AnalyticsStackedDatum(
        label: _shortName(name),
        completed: completed.toDouble(),
        inProgress: inProgress.toDouble(),
        pending: pending.toDouble(),
      ),
    );
  }

  result.sort((a, b) {
    final av = a.completed + a.inProgress + a.pending;
    final bv = b.completed + b.inProgress + b.pending;
    return bv.compareTo(av);
  });

  return result.take(8).toList();
}

String _shortName(String name) {
  final clean = name.trim();
  if (clean.isEmpty) return 'Unknown';
  return clean.split(' ').first;
}