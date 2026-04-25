import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class OfflineCacheService {
  static const String _devicesKey = 'offline_devices_cache_v2';
  static const String _issuesKey = 'offline_issues_cache_v2';
  static const String _solutionsKey = 'offline_solutions_cache_v2';
  static const String _pendingInspectionsKey = 'offline_pending_inspections_v2';
  static const String _lastCacheRefreshKey = 'offline_last_cache_refresh_v2';

  Future<void> saveDevices(List<dynamic> devices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_devicesKey, jsonEncode(devices));
    await prefs.setString(_lastCacheRefreshKey, DateTime.now().toIso8601String());
  }

  Future<void> upsertDevice(Map<String, dynamic> device) async {
    final devices = await getDevices();
    final id = device['id']?.toString();

    if (id == null || id.isEmpty) return;

    final index = devices.indexWhere((item) {
      return item['id']?.toString() == id;
    });

    if (index >= 0) {
      devices[index] = device;
    } else {
      devices.add(device);
    }

    await saveDevices(devices);
  }

  Future<List<Map<String, dynamic>>> getDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_devicesKey);

    if (raw == null || raw.trim().isEmpty) return [];

    final decoded = jsonDecode(raw);

    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>?> findDeviceOffline(String code) async {
    final q = code.trim().toLowerCase();

    if (q.isEmpty) return null;

    final devices = await getDevices();

    for (final device in devices) {
      final id = device['id']?.toString().toLowerCase() ?? '';
      final deviceCode = device['deviceCode']?.toString().toLowerCase() ?? '';
      final barcode = device['barcode']?.toString().toLowerCase() ?? '';
      final serialNumber = device['serialNumber']?.toString().toLowerCase() ?? '';
      final deviceName = device['deviceName']?.toString().toLowerCase() ?? '';

      if (id == q ||
          deviceCode == q ||
          barcode == q ||
          serialNumber == q ||
          deviceName == q) {
        return device;
      }
    }

    return null;
  }

  Future<void> saveIssues(List<dynamic> issues) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_issuesKey, jsonEncode(issues));
    await prefs.setString(_lastCacheRefreshKey, DateTime.now().toIso8601String());
  }

  Future<void> upsertIssuesForDeviceType({
    required int deviceTypeId,
    required List<dynamic> issues,
  }) async {
    final oldIssues = await getIssues();

    final withoutThisType = oldIssues.where((issue) {
      return issue['deviceTypeId']?.toString() != deviceTypeId.toString();
    }).toList();

    await saveIssues([...withoutThisType, ...issues]);
  }

  Future<List<Map<String, dynamic>>> getIssues() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_issuesKey);

    if (raw == null || raw.trim().isEmpty) return [];

    final decoded = jsonDecode(raw);

    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getIssuesByDeviceTypeOffline(
    int deviceTypeId,
  ) async {
    final issues = await getIssues();

    return issues.where((issue) {
      final currentDeviceTypeId = issue['deviceTypeId'];
      return currentDeviceTypeId?.toString() == deviceTypeId.toString();
    }).toList()
      ..sort((a, b) {
        final aCode = a['issueCode']?.toString() ?? '';
        final bCode = b['issueCode']?.toString() ?? '';
        return aCode.compareTo(bCode);
      });
  }

  Future<void> saveSolutions(List<dynamic> solutions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_solutionsKey, jsonEncode(solutions));
    await prefs.setString(_lastCacheRefreshKey, DateTime.now().toIso8601String());
  }

  Future<void> upsertSolutionsForIssue({
    required int issueId,
    required List<dynamic> solutions,
  }) async {
    final oldSolutions = await getSolutions();

    final withoutThisIssue = oldSolutions.where((solution) {
      return solution['issueId']?.toString() != issueId.toString();
    }).toList();

    await saveSolutions([...withoutThisIssue, ...solutions]);
  }

  Future<List<Map<String, dynamic>>> getSolutions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_solutionsKey);

    if (raw == null || raw.trim().isEmpty) return [];

    final decoded = jsonDecode(raw);

    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getSolutionsByIssueOffline(
    int issueId,
  ) async {
    final solutions = await getSolutions();

    return solutions.where((solution) {
      final currentIssueId = solution['issueId'];
      return currentIssueId?.toString() == issueId.toString();
    }).toList()
      ..sort((a, b) {
        final aOrder = int.tryParse(a['stepOrder']?.toString() ?? '') ?? 0;
        final bOrder = int.tryParse(b['stepOrder']?.toString() ?? '') ?? 0;
        return aOrder.compareTo(bOrder);
      });
  }

  Future<void> addPendingInspection(Map<String, dynamic> inspection) async {
    final pending = await getPendingInspections();

    pending.add({
      ...inspection,
      'localPendingId': DateTime.now().millisecondsSinceEpoch.toString(),
      'createdOfflineAt': DateTime.now().toIso8601String(),
      'syncStatus': 'PENDING',
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingInspectionsKey, jsonEncode(pending));
  }

  Future<List<Map<String, dynamic>>> getPendingInspections() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingInspectionsKey);

    if (raw == null || raw.trim().isEmpty) return [];

    final decoded = jsonDecode(raw);

    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> removePendingInspection(String localPendingId) async {
    final pending = await getPendingInspections();

    pending.removeWhere(
      (item) => item['localPendingId']?.toString() == localPendingId,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingInspectionsKey, jsonEncode(pending));
  }

  Future<int> pendingCount() async {
    final pending = await getPendingInspections();
    return pending.length;
  }

  Future<String?> lastCacheRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastCacheRefreshKey);
  }

  Future<void> clearPendingOnly() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingInspectionsKey);
  }

  Future<void> clearAllOfflineData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_devicesKey);
    await prefs.remove(_issuesKey);
    await prefs.remove(_solutionsKey);
    await prefs.remove(_pendingInspectionsKey);
    await prefs.remove(_lastCacheRefreshKey);
  }
}