// lib/admin/admin_models.dart

// ════════════════════════════════════════════════════════
//  ADMIN MODELS — access_track
//  Robust models for NestJS + Prisma backend responses
// ════════════════════════════════════════════════════════

int _intValue(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

double _doubleValue(dynamic value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

bool _boolValue(dynamic value, [bool fallback = false]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  final v = value.toString().toLowerCase().trim();
  if (v == 'true' || v == '1' || v == 'yes') return true;
  if (v == 'false' || v == '0' || v == 'no') return false;
  return fallback;
}

String? _str(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
  }
  return <Map<String, dynamic>>[];
}

int _pickInt(Map<String, dynamic> j, List<String> keys) {
  for (final key in keys) {
    if (j.containsKey(key) && j[key] != null) {
      return _intValue(j[key]);
    }
  }
  return 0;
}

String _buildLocationText(Map<String, dynamic> loc) {
  final parts = [
    _str(loc['name']),
    _str(loc['cluster']),
    _str(loc['building']),
    _str(loc['zone']),
    _str(loc['lane']),
    _str(loc['direction']),
  ].whereType<String>().where((e) => e.trim().isNotEmpty).toList();

  final unique = <String>[];
  for (final p in parts) {
    if (!unique.contains(p)) unique.add(p);
  }

  return unique.join(' — ');
}

// ════════════════════════════════════════════════════════
//  Admin Dashboard Stats
// ════════════════════════════════════════════════════════

class AdminStats {
  final int totalTechnicians;
  final int activeTechnicians;
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int urgentTasks;
  final int inProgressTasks;
  final int overdueTasks;
  final int totalDevices;
  final int okDevices;
  final int maintenanceDevices;
  final int outOfServiceDevices;
  final int totalInspectionsToday;
  final int totalInspectionsMonth;
  final int openReports;
  final int totalLocations;

  const AdminStats({
    required this.totalTechnicians,
    required this.activeTechnicians,
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.urgentTasks,
    required this.inProgressTasks,
    required this.overdueTasks,
    required this.totalDevices,
    required this.okDevices,
    required this.maintenanceDevices,
    required this.outOfServiceDevices,
    required this.totalInspectionsToday,
    required this.totalInspectionsMonth,
    required this.openReports,
    required this.totalLocations,
  });

  factory AdminStats.fromJson(Map<String, dynamic> j) {
    final stats = _map(j['stats']);
    final source = stats.isNotEmpty ? stats : j;

    return AdminStats(
      totalTechnicians: _pickInt(source, [
        'totalTechnicians',
        'technicians',
        'techniciansCount',
        'total_technicians',
      ]),
      activeTechnicians: _pickInt(source, [
        'activeTechnicians',
        'active_technicians',
        'activeTechniciansCount',
      ]),
      totalTasks: _pickInt(source, [
        'totalTasks',
        'tasks',
        'tasksCount',
        'total_tasks',
      ]),
      completedTasks: _pickInt(source, [
        'completedTasks',
        'completed_tasks',
        'tasksCompleted',
      ]),
      pendingTasks: _pickInt(source, [
        'pendingTasks',
        'pending_tasks',
      ]),
      urgentTasks: _pickInt(source, [
        'urgentTasks',
        'urgent_tasks',
        'emergencyTasks',
      ]),
      inProgressTasks: _pickInt(source, [
        'inProgressTasks',
        'in_progress_tasks',
      ]),
      overdueTasks: _pickInt(source, [
        'overdueTasks',
        'overdue_tasks',
      ]),
      totalDevices: _pickInt(source, [
        'totalDevices',
        'devices',
        'devicesCount',
        'total_devices',
      ]),
      okDevices: _pickInt(source, [
        'okDevices',
        'healthyDevices',
        'ok_devices',
      ]),
      maintenanceDevices: _pickInt(source, [
        'maintenanceDevices',
        'needsMaintenanceDevices',
        'maintenance_devices',
      ]),
      outOfServiceDevices: _pickInt(source, [
        'outOfServiceDevices',
        'faultDevices',
        'faultyDevices',
        'out_of_service_devices',
      ]),
      totalInspectionsToday: _pickInt(source, [
        'totalInspectionsToday',
        'todayInspections',
        'today_inspections',
      ]),
      totalInspectionsMonth: _pickInt(source, [
        'totalInspectionsMonth',
        'monthInspections',
        'monthlyInspections',
        'month_inspections',
      ]),
      openReports: _pickInt(source, [
        'openReports',
        'open_reports',
        'reports',
      ]),
      totalLocations: _pickInt(source, [
        'totalLocations',
        'locations',
        'locationsCount',
        'total_locations',
      ]),
    );
  }

  static AdminStats empty() => const AdminStats(
        totalTechnicians: 0,
        activeTechnicians: 0,
        totalTasks: 0,
        completedTasks: 0,
        pendingTasks: 0,
        urgentTasks: 0,
        inProgressTasks: 0,
        overdueTasks: 0,
        totalDevices: 0,
        okDevices: 0,
        maintenanceDevices: 0,
        outOfServiceDevices: 0,
        totalInspectionsToday: 0,
        totalInspectionsMonth: 0,
        openReports: 0,
        totalLocations: 0,
      );
}

// ════════════════════════════════════════════════════════
//  Task Model
// ════════════════════════════════════════════════════════

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final bool isEmergency;
  final String? assignedToId;
  final String? assignedToName;
  final String? assignedToEmail;
  final String? deviceId;
  final String? deviceName;
  final String? deviceCode;
  final String? locationId;
  final String? locationName;
  final String? notes;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isUrgent;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.isEmergency = false,
    this.assignedToId,
    this.assignedToName,
    this.assignedToEmail,
    this.deviceId,
    this.deviceName,
    this.deviceCode,
    this.locationId,
    this.locationName,
    this.notes,
    this.dueDate,
    required this.createdAt,
    this.completedAt,
    this.isUrgent = false,
  });

  String get statusAr {
    switch (status.toUpperCase()) {
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
        return status;
    }
  }

  String get statusEn {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'OVERDUE':
        return 'Overdue';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get priorityAr {
    switch (priority.toUpperCase()) {
      case 'LOW':
        return 'منخفضة';
      case 'MEDIUM':
        return 'متوسطة';
      case 'HIGH':
        return 'عالية';
      case 'URGENT':
        return 'طارئة';
      default:
        return priority;
    }
  }

  factory TaskModel.fromJson(Map<String, dynamic> j) {
    final assigned = _map(j['assignedUser']).isNotEmpty
        ? _map(j['assignedUser'])
        : _map(j['assignedTo']).isNotEmpty
            ? _map(j['assignedTo'])
            : _map(j['technician']);

    final device = _map(j['device']);

    final location = _map(j['location']).isNotEmpty
        ? _map(j['location'])
        : _map(device['location']);

    final priority = _str(j['priority']) ?? 'MEDIUM';

    final emergency = _boolValue(j['isEmergency']) ||
        _boolValue(j['is_emergency']) ||
        priority.toUpperCase() == 'URGENT';

    final title = _str(j['title']) ??
        _str(j['taskTitle']) ??
        _str(j['description']) ??
        'Task #${_str(j['id']) ?? ''}';

    return TaskModel(
      id: _str(j['id']) ?? '',
      title: title,
      description: _str(j['description']) ?? _str(j['notes']) ?? '',
      status: _str(j['status']) ?? 'PENDING',
      priority: priority,
      isEmergency: emergency,
      assignedToId: _str(assigned['id']) ??
          _str(j['assignedToId']) ??
          _str(j['assignedTo']) ??
          _str(j['technicianId']),
      assignedToName: _str(assigned['fullName']) ??
          _str(assigned['name']) ??
          _str(assigned['username']) ??
          _str(j['assignedToName']) ??
          _str(j['technicianName']),
      assignedToEmail: _str(assigned['email']),
      deviceId: _str(device['id']) ?? _str(j['deviceId']),
      deviceName: _str(device['name']) ??
          _str(device['deviceName']) ??
          _str(j['deviceName']),
      deviceCode: _str(device['deviceCode']) ??
          _str(device['code']) ??
          _str(device['qrCode']) ??
          _str(j['deviceCode']),
      locationId: _str(location['id']) ?? _str(j['locationId']),
      locationName: _str(location['name']) ??
          _str(j['locationName']) ??
          _buildLocationText(location),
      notes: _str(j['notes']),
      dueDate: _date(j['dueDate']) ?? _date(j['scheduledDate']),
      createdAt: _date(j['createdAt']) ?? DateTime.now(),
      completedAt: _date(j['completedAt']) ?? _date(j['finishedAt']),
      isUrgent: emergency,
    );
  }
}

// ════════════════════════════════════════════════════════
//  Technician Model
// ════════════════════════════════════════════════════════

class TechnicianModel {
  final String id;
  final String fullName;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? phone;
  final String? jobTitle;
  final String? region;
  final String? officeNumber;
  final String? notes;
  final String status;
  final bool isActive;
  final int totalInspections;
  final int monthInspections;
  final int totalTasksAssigned;
  final int totalTasksCompleted;
  final double completionRate;
  final DateTime? lastActivity;
  final List<ActivityLog> activityLog;

  const TechnicianModel({
    required this.id,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.phone,
    this.jobTitle,
    this.region,
    this.officeNumber,
    this.notes,
    required this.status,
    required this.isActive,
    this.totalInspections = 0,
    this.monthInspections = 0,
    this.totalTasksAssigned = 0,
    this.totalTasksCompleted = 0,
    this.completionRate = 0,
    this.lastActivity,
    this.activityLog = const [],
  });

  factory TechnicianModel.fromJson(Map<String, dynamic> j) {
    final stats = _map(j['stats']);

    final first = _str(j['firstName']) ?? '';
    final last = _str(j['lastName']) ?? '';
    final fallbackName = '$first $last'.trim();

    final fullName = _str(j['fullName']) ??
        _str(j['name']) ??
        fallbackName.ifEmpty(_str(j['username']) ?? _str(j['email']) ?? 'Technician');

    final logs = _mapList(j['activityLog'])
        .map(ActivityLog.fromJson)
        .toList();

    return TechnicianModel(
      id: _str(j['id']) ?? '',
      fullName: fullName,
      firstName: first.ifEmpty(fullName.split(' ').first),
      lastName: last.ifEmpty(
        fullName.split(' ').length > 1 ? fullName.split(' ').last : '',
      ),
      username: _str(j['username']) ?? _str(j['email']) ?? '',
      email: _str(j['email']) ?? '',
      phone: _str(j['phone']),
      jobTitle: _str(j['jobTitle']),
      region: _str(j['region']),
      officeNumber: _str(j['officeNumber']),
      notes: _str(j['notes']),
      status: _str(j['status']) ?? 'ACTIVE',
      isActive: _boolValue(j['isActive'], true),
      totalInspections: _intValue(
        stats['totalInspections'] ?? j['totalInspections'],
      ),
      monthInspections: _intValue(
        stats['monthInspections'] ?? j['monthInspections'],
      ),
      totalTasksAssigned: _intValue(
        stats['totalTasksAssigned'] ?? j['totalTasksAssigned'],
      ),
      totalTasksCompleted: _intValue(
        stats['totalTasksCompleted'] ?? j['totalTasksCompleted'],
      ),
      completionRate: _doubleValue(
        stats['completionRate'] ?? j['completionRate'],
      ),
      lastActivity: _date(j['lastActivity']) ??
          _date(j['updatedAt']) ??
          _date(j['createdAt']),
      activityLog: logs,
    );
  }
}

class ActivityLog {
  final String action;
  final String deviceName;
  final String result;
  final DateTime time;

  const ActivityLog({
    required this.action,
    required this.deviceName,
    required this.result,
    required this.time,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> j) {
    return ActivityLog(
      action: _str(j['action']) ?? 'فحص',
      deviceName: _str(j['deviceName']) ?? '',
      result: _str(j['result']) ?? '',
      time: _date(j['createdAt']) ?? _date(j['time']) ?? DateTime.now(),
    );
  }
}

// ════════════════════════════════════════════════════════
//  Admin Device Model
// ════════════════════════════════════════════════════════

class AdminDeviceModel {
  final String id;
  final String deviceCode;
  final String name;
  final String serialNumber;
  final String currentStatus;
  final String? typeName;
  final String? locationName;
  final String? locationBuilding;
  final String? locationId;
  final String? lastInspectorName;
  final DateTime? lastInspectionAt;
  final int inspectionCount;
  final int faultCount;
  final List<DeviceHistoryItem> history;

  const AdminDeviceModel({
    required this.id,
    required this.deviceCode,
    required this.name,
    required this.serialNumber,
    required this.currentStatus,
    this.typeName,
    this.locationName,
    this.locationBuilding,
    this.locationId,
    this.lastInspectorName,
    this.lastInspectionAt,
    this.inspectionCount = 0,
    this.faultCount = 0,
    this.history = const [],
  });

  String get statusAr {
    switch (currentStatus.toUpperCase()) {
      case 'OK':
        return 'سليم';
      case 'NOT_OK':
        return 'غير سليم';
      case 'PARTIAL':
        return 'جزئي';
      case 'NOT_REACHABLE':
        return 'غير متاح';
      case 'NEEDS_MAINTENANCE':
        return 'يحتاج صيانة';
      case 'UNDER_MAINTENANCE':
        return 'تحت الصيانة';
      case 'OUT_OF_SERVICE':
        return 'خارج الخدمة';
      default:
        return currentStatus;
    }
  }

  String get statusKey {
    switch (currentStatus.toUpperCase()) {
      case 'OK':
        return 'good';
      case 'NEEDS_MAINTENANCE':
      case 'UNDER_MAINTENANCE':
      case 'PARTIAL':
        return 'maintenance';
      case 'OUT_OF_SERVICE':
      case 'NOT_OK':
      case 'NOT_REACHABLE':
        return 'faulty';
      default:
        return 'review';
    }
  }

  factory AdminDeviceModel.fromJson(Map<String, dynamic> j) {
    final type = _map(j['deviceType']).isNotEmpty
        ? _map(j['deviceType'])
        : _map(j['type']);

    final location = _map(j['location']);

    final inspections = _mapList(j['inspections']);
    Map<String, dynamic> lastInspection = <String, dynamic>{};

    if (inspections.isNotEmpty) {
      inspections.sort((a, b) {
        final ad = _date(a['inspectedAt']) ?? _date(a['createdAt']) ?? DateTime(2000);
        final bd = _date(b['inspectedAt']) ?? _date(b['createdAt']) ?? DateTime(2000);
        return bd.compareTo(ad);
      });
      lastInspection = inspections.first;
    }

    final count = _map(j['_count']);
    final tech = _map(lastInspection['technician']);

    return AdminDeviceModel(
      id: _str(j['id']) ?? '',
      deviceCode: _str(j['deviceCode']) ??
          _str(j['code']) ??
          _str(j['qrCode']) ??
          _str(j['barcode']) ??
          '',
      name: _str(j['name']) ??
          _str(j['deviceName']) ??
          _str(j['deviceCode']) ??
          'Device',
      serialNumber: _str(j['serialNumber']) ?? _str(j['serial']) ?? '',
      currentStatus: _str(j['currentStatus']) ??
          _str(j['status']) ??
          _str(j['inspectionStatus']) ??
          'OK',
      typeName: _str(type['name']) ?? _str(type['typeName']) ?? _str(j['typeName']),
      locationName: _str(location['name']) ??
          _str(j['locationName']) ??
          _buildLocationText(location),
      locationBuilding: _str(location['building']) ??
          _str(location['cluster']) ??
          _str(j['building']),
      locationId: _str(location['id']) ?? _str(j['locationId']),
      lastInspectorName: _str(tech['fullName']) ??
          _str(tech['name']) ??
          _str(j['lastInspectorName']),
      lastInspectionAt: _date(lastInspection['inspectedAt']) ??
          _date(lastInspection['createdAt']) ??
          _date(j['lastInspectionAt']),
      inspectionCount: _intValue(
        count['inspections'] ?? j['inspectionCount'] ?? j['totalInspections'],
      ),
      faultCount: _intValue(j['faultCount']),
      history: _mapList(j['history']).map(DeviceHistoryItem.fromJson).toList(),
    );
  }
}

class DeviceHistoryItem {
  final String oldStatus;
  final String newStatus;
  final String? changedByName;
  final String? note;
  final DateTime changedAt;

  const DeviceHistoryItem({
    required this.oldStatus,
    required this.newStatus,
    this.changedByName,
    this.note,
    required this.changedAt,
  });

  factory DeviceHistoryItem.fromJson(Map<String, dynamic> j) {
    final changedBy = _map(j['changedBy']);

    return DeviceHistoryItem(
      oldStatus: _str(j['oldStatus']) ?? '',
      newStatus: _str(j['newStatus']) ?? _str(j['status']) ?? '',
      changedByName: _str(changedBy['fullName']) ??
          _str(changedBy['name']) ??
          _str(j['changedByName']),
      note: _str(j['note']) ?? _str(j['notes']),
      changedAt: _date(j['changedAt']) ?? _date(j['createdAt']) ?? DateTime.now(),
    );
  }
}

// ════════════════════════════════════════════════════════
//  Location Model
// ════════════════════════════════════════════════════════

class LocationModel {
  final String id;
  final String name;
  final String? cluster;
  final String? building;
  final String? zone;
  final String? address;
  final String? notes;
  final int deviceCount;
  final int okDeviceCount;
  final int faultyDeviceCount;

  const LocationModel({
    required this.id,
    required this.name,
    this.cluster,
    this.building,
    this.zone,
    this.address,
    this.notes,
    this.deviceCount = 0,
    this.okDeviceCount = 0,
    this.faultyDeviceCount = 0,
  });

  factory LocationModel.fromJson(Map<String, dynamic> j) {
    final count = _map(j['_count']);
    final name = _str(j['name']) ?? _buildLocationText(j);

    return LocationModel(
      id: _str(j['id']) ?? '',
      name: name.ifEmpty('Location'),
      cluster: _str(j['cluster']),
      building: _str(j['building']),
      zone: _str(j['zone']),
      address: _str(j['address']),
      notes: _str(j['notes']),
      deviceCount: _intValue(j['deviceCount'] ?? count['devices']),
      okDeviceCount: _intValue(j['okDeviceCount']),
      faultyDeviceCount: _intValue(j['faultyDeviceCount']),
    );
  }
}

// ════════════════════════════════════════════════════════
//  Inspection Detail
// ════════════════════════════════════════════════════════

class InspectionDetail {
  final String id;
  final String reportNumber;
  final String deviceName;
  final String deviceCode;
  final String locationText;
  final String technicianName;
  final String inspectionStatus;
  final String? notes;
  final String? issueReason;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final DateTime inspectedAt;

  const InspectionDetail({
    required this.id,
    required this.reportNumber,
    required this.deviceName,
    required this.deviceCode,
    required this.locationText,
    required this.technicianName,
    required this.inspectionStatus,
    this.notes,
    this.issueReason,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.inspectedAt,
  });

  String get statusAr {
    switch (inspectionStatus.toUpperCase()) {
      case 'OK':
        return 'سليم';
      case 'NOT_OK':
        return 'غير سليم';
      case 'PARTIAL':
        return 'جزئي';
      case 'NOT_REACHABLE':
        return 'غير متاح';
      default:
        return inspectionStatus;
    }
  }

  factory InspectionDetail.fromJson(Map<String, dynamic> j) {
    final device = _map(j['device']);
    final tech = _map(j['technician']).isNotEmpty
        ? _map(j['technician'])
        : _map(j['user']);

    final loc = _map(device['location']).isNotEmpty
        ? _map(device['location'])
        : _map(j['location']);

    final images = _mapList(j['images']);

    String? imageUrl = _str(j['imageUrl']) ?? _str(j['photoUrl']);
    if (imageUrl == null && images.isNotEmpty) {
      imageUrl = _str(images.first['imageUrl']) ??
          _str(images.first['url']) ??
          _str(images.first['path']);
    }

    return InspectionDetail(
      id: _str(j['id']) ?? '',
      reportNumber: _str(j['reportNumber']) ?? 'RPT-${_str(j['id']) ?? '0'}',
      deviceName: _str(device['name']) ??
          _str(device['deviceName']) ??
          _str(j['deviceName']) ??
          '',
      deviceCode: _str(device['deviceCode']) ??
          _str(device['qrCode']) ??
          _str(j['deviceCode']) ??
          '',
      locationText: _str(j['locationText']) ??
          _str(j['locationName']) ??
          _buildLocationText(loc),
      technicianName: _str(tech['fullName']) ??
          _str(tech['name']) ??
          _str(tech['username']) ??
          _str(j['technicianName']) ??
          '',
      inspectionStatus: _str(j['inspectionStatus']) ??
          _str(j['status']) ??
          _str(j['currentStatus']) ??
          'OK',
      notes: _str(j['notes']),
      issueReason: _str(j['issueReason']) ?? _str(j['reason']),
      imageUrl: imageUrl,
      latitude: _doubleValue(j['latitude']),
      longitude: _doubleValue(j['longitude']),
      inspectedAt: _date(j['inspectedAt']) ??
          _date(j['createdAt']) ??
          _date(j['updatedAt']) ??
          DateTime.now(),
    );
  }
}

// ════════════════════════════════════════════════════════
//  Create / Update Requests
// ════════════════════════════════════════════════════════

class CreateTaskRequest {
  final String title;
  final String description;
  final String assignedToId;
  final String? deviceId;
  final String? locationId;
  final String priority;
  final bool isEmergency;
  final DateTime dueDate;
  final String? notes;

  const CreateTaskRequest({
    required this.title,
    required this.description,
    required this.assignedToId,
    this.deviceId,
    this.locationId,
    required this.priority,
    this.isEmergency = false,
    required this.dueDate,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'assignedToId': int.tryParse(assignedToId) ?? assignedToId,
        'assignedTo': int.tryParse(assignedToId) ?? assignedToId,
        if (deviceId != null) 'deviceId': int.tryParse(deviceId!) ?? deviceId,
        if (locationId != null) 'locationId': int.tryParse(locationId!) ?? locationId,
        'priority': isEmergency ? 'URGENT' : priority,
        'isEmergency': isEmergency,
        'status': 'PENDING',
        'scheduledDate': dueDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        if (notes != null) 'notes': notes,
      };
}

class CreateTechnicianRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final String password;
  final String? phone;
  final String? jobTitle;
  final String? region;
  final String? officeNumber;
  final String? notes;
  final int roleId;

  const CreateTechnicianRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    required this.password,
    this.phone,
    this.jobTitle,
    this.region,
    this.officeNumber,
    this.notes,
    this.roleId = 3,
  });

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'fullName': '$firstName $lastName',
        'email': email,
        'username': username,
        'password': password,
        if (phone != null) 'phone': phone,
        if (jobTitle != null) 'jobTitle': jobTitle,
        if (region != null) 'region': region,
        if (officeNumber != null) 'officeNumber': officeNumber,
        if (notes != null) 'notes': notes,
        'roleId': roleId,
        'isActive': true,
        'status': 'ACTIVE',
      };
}

class UpdateTechnicianRequest {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? jobTitle;
  final String? region;
  final String? officeNumber;
  final String? notes;
  final bool? isActive;
  final String? status;

  const UpdateTechnicianRequest({
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.jobTitle,
    this.region,
    this.officeNumber,
    this.notes,
    this.isActive,
    this.status,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    if (firstName != null) map['firstName'] = firstName;
    if (lastName != null) map['lastName'] = lastName;
    if (firstName != null && lastName != null) {
      map['fullName'] = '$firstName $lastName';
    }
    if (email != null) map['email'] = email;
    if (phone != null) map['phone'] = phone;
    if (jobTitle != null) map['jobTitle'] = jobTitle;
    if (region != null) map['region'] = region;
    if (officeNumber != null) map['officeNumber'] = officeNumber;
    if (notes != null) map['notes'] = notes;
    if (isActive != null) map['isActive'] = isActive;
    if (status != null) map['status'] = status;

    return map;
  }
}

// ════════════════════════════════════════════════════════
//  Analytics Models
// ════════════════════════════════════════════════════════

class ChartData {
  final String label;
  final int value;
  final String color;

  const ChartData({
    required this.label,
    required this.value,
    required this.color,
  });
}

class AnalyticsBarDatum {
  final String label;
  final double value;

  const AnalyticsBarDatum({
    required this.label,
    required this.value,
  });
}

class AnalyticsLineDatum {
  final String label;
  final double value;

  const AnalyticsLineDatum({
    required this.label,
    required this.value,
  });
}

class AnalyticsStackedDatum {
  final String label;
  final double completed;
  final double inProgress;
  final double pending;

  const AnalyticsStackedDatum({
    required this.label,
    required this.completed,
    required this.inProgress,
    required this.pending,
  });
}

class AnalyticsLegendItem {
  final String label;
  final int value;

  const AnalyticsLegendItem({
    required this.label,
    required this.value,
  });
}

class AdminAnalyticsData {
  final AdminStats stats;
  final List<AnalyticsLegendItem> deviceStatus;
  final List<AnalyticsLegendItem> taskStatus;
  final List<AnalyticsBarDatum> devicesByBuilding;
  final List<AnalyticsBarDatum> devicesByType;
  final List<AnalyticsLineDatum> taskCompletionTrend;
  final List<AnalyticsBarDatum> technicianPerformance;
  final List<AnalyticsLineDatum> inspectionsOverTime;
  final List<AnalyticsStackedDatum> taskExecutionByTechnician;

  const AdminAnalyticsData({
    required this.stats,
    required this.deviceStatus,
    required this.taskStatus,
    required this.devicesByBuilding,
    required this.devicesByType,
    required this.taskCompletionTrend,
    required this.technicianPerformance,
    required this.inspectionsOverTime,
    required this.taskExecutionByTechnician,
  });

  factory AdminAnalyticsData.empty() => AdminAnalyticsData(
        stats: AdminStats.empty(),
        deviceStatus: const [],
        taskStatus: const [],
        devicesByBuilding: const [],
        devicesByType: const [],
        taskCompletionTrend: const [],
        technicianPerformance: const [],
        inspectionsOverTime: const [],
        taskExecutionByTechnician: const [],
      );
}

extension _StringX on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}