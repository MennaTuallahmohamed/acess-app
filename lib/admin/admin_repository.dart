// lib/admin/admin_repository.dart

import 'package:access_track/admin/admin_models.dart';
import 'package:access_track/core/api/api_client.dart';
import 'package:dio/dio.dart';

// ════════════════════════════════════════════════════════
//  ADMIN REPOSITORY — all admin backend endpoints
// ════════════════════════════════════════════════════════

class AdminRepository {
  final Dio _dio;

  AdminRepository(this._dio);

  // ══════════════════════════════════════════════════════
  //  DASHBOARD
  // ══════════════════════════════════════════════════════

  Future<AdminStats> getAdminStats() async {
    try {
      final res = await _dio.get('/dashboard/admin');
      return AdminStats.fromJson(_unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ══════════════════════════════════════════════════════
  //  TASKS
  // ══════════════════════════════════════════════════════

  Future<List<TaskModel>> getTasks({
    String? status,
    String? assignedToId,
    String? priority,
    String? deviceId,
    String? locationId,
    int? limit,
  }) async {
    try {
      final res = await _dio.get(
        '/inspection-tasks',
        queryParameters: {
          if (_valid(status)) 'status': status,
          if (_valid(assignedToId)) 'assignedToId': assignedToId,
          if (_valid(assignedToId)) 'assignedTo': assignedToId,
          if (_valid(priority)) 'priority': priority,
          if (_valid(deviceId)) 'deviceId': deviceId,
          if (_valid(locationId)) 'locationId': locationId,
          if (limit != null) 'limit': limit,
        },
      );

      return _unwrapList(res.data)
          .map((e) => TaskModel.fromJson(_asMap(e)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<TaskModel>> getUrgentTasks() async {
    try {
      final tasks = await getTasks(priority: 'URGENT');
      if (tasks.isNotEmpty) return tasks;

      final all = await getTasks();
      return all
          .where((t) => t.isUrgent || t.priority.toUpperCase() == 'URGENT')
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TaskModel> getTaskById(String id) async {
    try {
      final res = await _dio.get('/inspection-tasks/$id');
      return TaskModel.fromJson(_unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TaskModel> createTask(CreateTaskRequest req) async {
    try {
      final res = await _dio.post('/inspection-tasks', data: req.toJson());
      return TaskModel.fromJson(_unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TaskModel> updateTask(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.patch('/inspection-tasks/$id', data: data);
      return TaskModel.fromJson(_unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _dio.delete('/inspection-tasks/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TaskModel> reassignTask(String taskId, String newTechnicianId) {
    return updateTask(taskId, {
      'assignedToId': int.tryParse(newTechnicianId) ?? newTechnicianId,
      'assignedTo': int.tryParse(newTechnicianId) ?? newTechnicianId,
      'status': 'PENDING',
    });
  }

  // ══════════════════════════════════════════════════════
  //  TECHNICIANS
  // ══════════════════════════════════════════════════════

  Future<List<TechnicianModel>> getTechnicians({
    bool? activeOnly,
    String? region,
  }) async {
    try {
      final res = await _dio.get(
        '/users',
        queryParameters: {
          'role': 'TECHNICIAN',
          if (activeOnly == true) 'isActive': true,
          if (_valid(region)) 'region': region,
        },
      );

      final list = _unwrapList(res.data)
          .map((e) => TechnicianModel.fromJson(_asMap(e)))
          .toList();

      if (activeOnly == true) {
        return list
            .where((t) => t.isActive || t.status.toUpperCase() == 'ACTIVE')
            .toList();
      }

      return list;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TechnicianModel> getTechnicianById(String id) async {
    try {
      final res = await _dio.get('/users/$id');
      return TechnicianModel.fromJson(_unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<InspectionDetail>> getTechnicianActivity(
    String techId, {
    int limit = 50,
  }) async {
    try {
      final res = await _dio.get(
        '/inspections',
        queryParameters: {
          'technicianId': techId,
          'limit': limit,
        },
      );

      return _unwrapList(res.data)
          .map((e) => InspectionDetail.fromJson(_asMap(e)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TechnicianModel> createTechnician(CreateTechnicianRequest req) async {
    try {
      final res = await _dio.post('/users', data: req.toJson());
      return TechnicianModel.fromJson(_unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TechnicianModel> updateTechnician(
    String id,
    UpdateTechnicianRequest req,
  ) async {
    try {
      final res = await _dio.patch('/users/$id', data: req.toJson());
      return TechnicianModel.fromJson(_unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TechnicianModel> toggleTechnicianStatus(
    String id, {
    required bool isActive,
  }) async {
    try {
      final res = await _dio.patch(
        '/users/$id',
        data: {
          'isActive': isActive,
          'status': isActive ? 'ACTIVE' : 'INACTIVE',
        },
      );

      return TechnicianModel.fromJson(_unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ══════════════════════════════════════════════════════
  //  DEVICES
  // ══════════════════════════════════════════════════════

  Future<List<AdminDeviceModel>> getDevices({
    String? status,
    String? locationId,
    String? typeId,
    int? limit,
  }) async {
    try {
      final res = await _dio.get(
        '/devices',
        queryParameters: {
          if (_valid(status)) 'status': status,
          if (_valid(locationId)) 'locationId': locationId,
          if (_valid(typeId)) 'typeId': typeId,
          if (limit != null) 'limit': limit,
        },
      );

      return _unwrapList(res.data)
          .map((e) => AdminDeviceModel.fromJson(_asMap(e)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AdminDeviceModel> getDeviceById(String id) async {
    try {
      final res = await _dio.get('/devices/$id');
      return AdminDeviceModel.fromJson(_unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<DeviceHistoryItem>> getDeviceHistory(String deviceId) async {
    try {
      final res = await _dio.get('/device-status-history/device/$deviceId');

      return _unwrapList(res.data)
          .map((e) => DeviceHistoryItem.fromJson(_asMap(e)))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return <DeviceHistoryItem>[];
      throw ApiException.fromDio(e);
    }
  }

  // ══════════════════════════════════════════════════════
  //  INSPECTIONS
  // ══════════════════════════════════════════════════════

  Future<List<InspectionDetail>> getInspections({
    DateTime? from,
    DateTime? to,
    String? technicianId,
    String? locationId,
    String? deviceId,
    String? status,
    int limit = 300,
  }) async {
    try {
      final res = await _dio.get(
        '/inspections',
        queryParameters: {
          if (from != null) 'from': from.toIso8601String(),
          if (to != null) 'to': to.toIso8601String(),
          if (_valid(technicianId)) 'technicianId': technicianId,
          if (_valid(locationId)) 'locationId': locationId,
          if (_valid(deviceId)) 'deviceId': deviceId,
          if (_valid(status)) 'status': status,
          if (_valid(status)) 'inspectionStatus': status,
          'limit': limit,
        },
      );

      return _unwrapList(res.data)
          .map((e) => InspectionDetail.fromJson(_asMap(e)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ══════════════════════════════════════════════════════
  //  LOCATIONS
  // ══════════════════════════════════════════════════════

  Future<List<LocationModel>> getLocations() async {
    try {
      final res = await _dio.get('/locations');

      return _unwrapList(res.data)
          .map((e) => LocationModel.fromJson(_asMap(e)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ══════════════════════════════════════════════════════
  //  CHARTS / OPTIONAL BACKEND ANALYTICS
  // ══════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getTasksChart() async {
    try {
      final res = await _dio.get('/dashboard/charts/tasks-status');
      return _unwrapMap(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return <String, dynamic>{};
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> getDevicesChart() async {
    try {
      final res = await _dio.get('/dashboard/charts/devices-by-status');
      return _unwrapMap(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return <String, dynamic>{};
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> getInspectionsChart() async {
    try {
      final res = await _dio.get('/dashboard/charts/inspections-over-time');
      return _unwrapMap(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return <String, dynamic>{};
      throw ApiException.fromDio(e);
    }
  }

  // ══════════════════════════════════════════════════════
  //  Helpers
  // ══════════════════════════════════════════════════════

  bool _valid(String? v) => v != null && v.trim().isNotEmpty && v != 'ALL';

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  Map<String, dynamic> _unwrapMap(dynamic raw) {
    if (raw is Map) {
      final map = raw.cast<String, dynamic>();

      final data = map['data'];
      if (data is Map) return data.cast<String, dynamic>();

      final result = map['result'];
      if (result is Map) return result.cast<String, dynamic>();

      final item = map['item'];
      if (item is Map) return item.cast<String, dynamic>();

      return map;
    }

    return <String, dynamic>{};
  }

  List<dynamic> _unwrapList(dynamic raw) {
    if (raw is List) return raw;

    if (raw is Map) {
      final map = raw.cast<String, dynamic>();

      final data = map['data'];
      if (data is List) return data;

      final items = map['items'];
      if (items is List) return items;

      final result = map['result'];
      if (result is List) return result;

      final rows = map['rows'];
      if (rows is List) return rows;

      final records = map['records'];
      if (records is List) return records;
    }

    return <dynamic>[];
  }
}