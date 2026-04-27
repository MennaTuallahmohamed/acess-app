import 'dart:async';
import 'dart:io';

import 'package:access_track/app_constants.dart';
import 'package:access_track/core/api/api_client.dart';
import 'package:access_track/core/api/offline_cache_service.dart';
import 'package:access_track/core/modals/models.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final technicianRepositoryProvider = Provider<TechnicianRepository>((ref) {
  return TechnicianRepository(ref.watch(apiDioProvider));
});

class InspectionSubmissionResult {
  final String reportNumber;
  final int? inspectionId;
  final int? inspectionIssueId;
  final bool savedOffline;

  const InspectionSubmissionResult({
    required this.reportNumber,
    this.inspectionId,
    this.inspectionIssueId,
    this.savedOffline = false,
  });
}

class TaskNotificationModel {
  final String id;
  final String deviceId;
  final String deviceName;
  final String deviceCode;
  final String status;
  final DateTime? scheduledDate;
  final String cluster;
  final String building;
  final String zone;
  final String lane;
  final String direction;

  const TaskNotificationModel({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.deviceCode,
    required this.status,
    required this.scheduledDate,
    required this.cluster,
    required this.building,
    required this.zone,
    required this.lane,
    required this.direction,
  });
}

class TechnicianRepository {
  final Dio _dio;
  final OfflineCacheService _offline = OfflineCacheService();

  static const String _issuesBase = '/issues';
  static const String _issuesByDeviceTypeBase = '/issues/device-type';
  static const String _inspectionIssueReportPath = '/issues/inspection/report';
  static const String _inspectionIssueActionPath = '/issues/inspection/action';
  static const String _inspectionIssueItemBase = '/issues/inspection-item';

  TechnicianRepository(this._dio);

  Future<bool> _hasNetworkSignal() async {
    final result = await Connectivity().checkConnectivity();

    if (result.contains(ConnectivityResult.none)) {
      return false;
    }

    return true;
  }

  bool _isOfflineDioError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown;
  }

  Future<List<TaskNotificationModel>> getMyTasks() async {
    try {
      final response = await _dio.get(ApiConstants.myTasks);

      return unwrapList(response.data)
          .map((item) => _mapTask(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      if (_isOfflineDioError(error)) {
        debugPrint('MY TASKS OFFLINE: ${error.message}');
        return [];
      }

      throw ApiException.fromDio(error);
    }
  }

  Future<List<ReportModel>> getMyReports(String technicianId) async {
    try {
      final response = await _dio.get(
        '/inspections/my',
        queryParameters: {
          'technicianId': technicianId,
        },
      );

      return unwrapList(response.data)
          .map((item) => _mapInspectionToReport(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } on DioException catch (error) {
      if (error.response?.statusCode == 404 ||
          error.response?.statusCode == 400 ||
          _isOfflineDioError(error)) {
        debugPrint('GET MY REPORTS skipped: ${error.response?.data}');
        return [];
      }

      throw ApiException.fromDio(error);
    }
  }

  Future<void> refreshOfflineCache() async {
    final hasSignal = await _hasNetworkSignal();

    if (!hasSignal) {
      debugPrint('OFFLINE CACHE: no network signal');
      return;
    }

    try {
      final devicesResponse = await _dio.get(
        '/devices',
        options: Options(
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final devices = unwrapList(devicesResponse.data);
      await _offline.saveDevices(devices);

      final issuesResponse = await _dio.get(
        '/issues',
        options: Options(
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final issues = unwrapList(issuesResponse.data);
      await _offline.saveIssues(issues);

      final List<dynamic> allSolutions = [];

      for (final issueRaw in issues) {
        try {
          final issue = issueRaw as Map<String, dynamic>;
          final issueId = (issue['id'] as num?)?.toInt();

          if (issueId == null) continue;

          final solutionsResponse = await _dio.get(
            '$_issuesBase/$issueId/solutions',
            options: Options(
              sendTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
            ),
          );

          final solutions = unwrapList(solutionsResponse.data);
          allSolutions.addAll(solutions);
        } catch (e) {
          debugPrint('CACHE SOLUTIONS ERROR: $e');
        }
      }

      await _offline.saveSolutions(allSolutions);

      debugPrint(
        'OFFLINE CACHE SAVED: devices=${devices.length}, issues=${issues.length}, solutions=${allSolutions.length}',
      );
    } catch (e) {
      debugPrint('OFFLINE CACHE ERROR: $e');
    }
  }

  Future<DeviceModel> getDeviceByCode(String code) async {
    final hasSignal = await _hasNetworkSignal();

    if (hasSignal) {
      try {
        final response = await _dio.get(
          ApiConstants.deviceSearch,
          queryParameters: {
            'q': code.trim(),
          },
          options: Options(
            sendTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
          ),
        );

        final deviceJson = unwrapMap(response.data);
        await _offline.upsertDevice(deviceJson);

        return _mapDevice(deviceJson);
      } on DioException catch (error) {
        if (!_isOfflineDioError(error)) {
          throw ApiException.fromDio(error);
        }

        debugPrint('DEVICE ONLINE FAILED, TRY OFFLINE: ${error.message}');
      }
    }

    final offlineDevice = await _offline.findDeviceOffline(code);

    if (offlineDevice != null) {
      return _mapDevice(offlineDevice);
    }

    throw const ApiException(
      'لا يوجد اتصال بالإنترنت والجهاز غير محفوظ محليًا. افتحي النت مرة واحدة لتحميل الأجهزة.',
    );
  }

  Future<DeviceModel> getDeviceBySecretCode(String secretCode) async {
    final cleanCode = secretCode.trim();

    if (cleanCode.isEmpty) {
      throw const ApiException('QR Code غير صالح');
    }

    final hasSignal = await _hasNetworkSignal();

    if (!hasSignal) {
      throw const ApiException(
        'لا يوجد اتصال بالإنترنت. QR Code يحتاج اتصال بالباك إند للتحقق من الجهاز.',
      );
    }

    try {
      final response = await _dio.get(
        '/devices/scan/${Uri.encodeComponent(cleanCode)}',
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );

      final deviceJson = unwrapMap(response.data);

      await _offline.upsertDevice(deviceJson);

      return _mapDevice(deviceJson);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        throw const ApiException('لا يوجد جهاز مرتبط بهذا QR Code');
      }

      throw ApiException.fromDio(error);
    }
  }

  Future<DeviceModel> searchDeviceManual(String value) async {
    final cleanValue = value.trim();

    if (cleanValue.isEmpty) {
      throw const ApiException('برجاء إدخال كود الجهاز أو IP أو Serial Number');
    }

    return getDeviceByCode(cleanValue);
  }

  Future<void> logQrScanAttempt({
    required String scannedCode,
    required bool success,
    required int attemptNumber,
    String? reason,
  }) async {
    try {
      await _dio.post(
        '/devices/scan-attempts',
        data: {
          'scannedCode': scannedCode.trim(),
          'success': success,
          'attemptNumber': attemptNumber,
          'reason': reason,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Accept': 'application/json',
          },
        ),
      );
    } catch (e) {
      debugPrint('QR SCAN ATTEMPT LOG SKIPPED: $e');
    }
  }

  Future<List<InspectionIssueOption>> getIssuesForDevice(
    DeviceModel device,
  ) async {
    final int? deviceTypeId = _resolveIssueDeviceTypeId(device);

    if (deviceTypeId == null) return [];

    final hasSignal = await _hasNetworkSignal();

    if (hasSignal) {
      try {
        final response = await _dio.get(
          '$_issuesByDeviceTypeBase/$deviceTypeId',
          options: Options(
            sendTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
          ),
        );

        final list = unwrapList(response.data);

        await _offline.upsertIssuesForDeviceType(
          deviceTypeId: deviceTypeId,
          issues: list,
        );

        return list
            .map(
              (item) => InspectionIssueOption.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      } on DioException catch (error) {
        if (!_isOfflineDioError(error)) {
          throw ApiException.fromDio(error);
        }

        debugPrint('ISSUES ONLINE FAILED, TRY OFFLINE: ${error.message}');
      }
    }

    final offlineIssues =
        await _offline.getIssuesByDeviceTypeOffline(deviceTypeId);

    return offlineIssues
        .map((item) => InspectionIssueOption.fromJson(item))
        .toList();
  }

  Future<List<IssueSolutionModel>> getIssueSolutions(int issueId) async {
    final hasSignal = await _hasNetworkSignal();

    if (hasSignal) {
      try {
        final response = await _dio.get(
          '$_issuesBase/$issueId/solutions',
          options: Options(
            sendTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
          ),
        );

        final list = unwrapList(response.data);

        await _offline.upsertSolutionsForIssue(
          issueId: issueId,
          solutions: list,
        );

        return list
            .map(
              (item) => IssueSolutionModel.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList()
          ..sort((a, b) => a.stepOrder.compareTo(b.stepOrder));
      } on DioException catch (error) {
        if (!_isOfflineDioError(error)) {
          throw ApiException.fromDio(error);
        }

        debugPrint('SOLUTIONS ONLINE FAILED, TRY OFFLINE: ${error.message}');
      }
    }

    final offlineSolutions = await _offline.getSolutionsByIssueOffline(issueId);

    return offlineSolutions
        .map((item) => IssueSolutionModel.fromJson(item))
        .toList()
      ..sort((a, b) => a.stepOrder.compareTo(b.stepOrder));
  }

  Future<InspectionSubmissionResult> submitInspection(
    InspectionDraft draft,
  ) async {
    try {
      final int? parsedDeviceId = int.tryParse(draft.deviceId.trim());

      if (parsedDeviceId == null) {
        throw const ApiException('رقم الجهاز غير صحيح');
      }

      final int? parsedTechnicianId = int.tryParse(draft.inspectorId.trim());

      if (parsedTechnicianId == null) {
        throw const ApiException('رقم الفني غير صحيح');
      }

      final bool isGoodInspection =
          draft.isGood || draft.result.trim().toLowerCase() == 'good';

      if (draft.imagePath == null || draft.imagePath!.trim().isEmpty) {
        throw const ApiException('لازم ترفعي صورة الجهاز قبل الإرسال');
      }

      final imageFile = File(draft.imagePath!);

      if (!await imageFile.exists()) {
        throw const ApiException('الصورة المختارة غير موجودة');
      }

      final bool noRegisteredSolution =
          draft.notes.contains('لم أجد حل مسجل لهذه المشكلة') ||
              draft.notes.contains('لم أجد حل') ||
              draft.notes.contains('لا توجد حلول مسجلة');

      if (!isGoodInspection &&
          draft.completedSolutionIds.isEmpty &&
          !noRegisteredSolution) {
        throw const ApiException('لازم تعملي Done لخطوة حل واحدة على الأقل');
      }

      if (!isGoodInspection && draft.issueId == null) {
        throw const ApiException('لا يوجد Issue ID لإرسال المشكلة للباك اند');
      }

      final String mappedStatus = _mapInspectionStatus(draft.result);
      final String fullNotes = _buildInspectionNotes(draft);

      final hasSignal = await _hasNetworkSignal();

      if (!hasSignal) {
        await _saveInspectionOffline(
          draft: draft,
          parsedDeviceId: parsedDeviceId,
          parsedTechnicianId: parsedTechnicianId,
          mappedStatus: mappedStatus,
          fullNotes: fullNotes,
        );

        return InspectionSubmissionResult(
          reportNumber: 'OFFLINE-${DateTime.now().millisecondsSinceEpoch}',
          inspectionId: null,
          savedOffline: true,
        );
      }

      try {
        return await _sendInspectionOnline(
          draft: draft,
          parsedDeviceId: parsedDeviceId,
          parsedTechnicianId: parsedTechnicianId,
          mappedStatus: mappedStatus,
          fullNotes: fullNotes,
        );
      } on DioException catch (error) {
        if (_isOfflineDioError(error)) {
          await _saveInspectionOffline(
            draft: draft,
            parsedDeviceId: parsedDeviceId,
            parsedTechnicianId: parsedTechnicianId,
            mappedStatus: mappedStatus,
            fullNotes: fullNotes,
          );

          return InspectionSubmissionResult(
            reportNumber: 'OFFLINE-${DateTime.now().millisecondsSinceEpoch}',
            inspectionId: null,
            savedOffline: true,
          );
        }

        throw ApiException.fromDio(error);
      }
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> _saveInspectionOffline({
    required InspectionDraft draft,
    required int parsedDeviceId,
    required int parsedTechnicianId,
    required String mappedStatus,
    required String fullNotes,
  }) async {
    await _offline.addPendingInspection({
      'deviceId': parsedDeviceId,
      'technicianId': parsedTechnicianId,
      'inspectionStatus': mappedStatus,
      'notes': fullNotes,
      'latitude': draft.latitude,
      'longitude': draft.longitude,
      'deviceCode': draft.deviceCode,
      'imagePath': draft.imagePath,
      'issueId': draft.issueId,
      'issueCode': draft.issueCode,
      'issueTitle': draft.issueTitle,
      'completedSolutionIds': draft.completedSolutionIds,
      'deviceTypeId': draft.deviceTypeId,
      'isGood': draft.isGood,
      'result': draft.result,
    });

    debugPrint('OFFLINE INSPECTION SAVED SUCCESSFULLY');
  }

  Future<InspectionSubmissionResult> _sendInspectionOnline({
    required InspectionDraft draft,
    required int parsedDeviceId,
    required int parsedTechnicianId,
    required String mappedStatus,
    required String fullNotes,
  }) async {
    final Map<String, dynamic> payload = {
      'deviceId': parsedDeviceId,
      'technicianId': parsedTechnicianId,
      'inspectionStatus': mappedStatus,
      'notes': fullNotes,
      'latitude': draft.latitude,
      'longitude': draft.longitude,
      if (draft.deviceCode.trim().isNotEmpty)
        'locationText': 'Device code: ${draft.deviceCode}',
    };

    final formData = FormData.fromMap({
      ...payload,
      'image': await MultipartFile.fromFile(
        draft.imagePath!,
        filename: draft.imagePath!.split(Platform.pathSeparator).last,
      ),
    });

    debugPrint('SUBMIT INSPECTION ONLINE PAYLOAD: $payload');
    debugPrint('SUBMIT INSPECTION ONLINE IMAGE PATH: ${draft.imagePath}');

    final response = await _dio.post(
      ApiConstants.submitInspection,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(minutes: 3),
        receiveTimeout: const Duration(minutes: 3),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    final raw = unwrapMap(response.data);
    final int? inspectionId = _extractInspectionId(raw);
    final String reportNumber = _extractReportNumber(raw);

    if (inspectionId != null && draft.issueId != null) {
      await _syncIssueFlowInBackground(
        inspectionId: inspectionId,
        draft: draft,
        notes: fullNotes,
      );
    }

    return InspectionSubmissionResult(
      reportNumber: reportNumber,
      inspectionId: inspectionId,
      savedOffline: false,
    );
  }

  Future<int> syncPendingInspections() async {
    final hasSignal = await _hasNetworkSignal();

    if (!hasSignal) {
      debugPrint('SYNC PENDING: no network signal');
      return 0;
    }

    final pending = await _offline.getPendingInspections();

    int synced = 0;

    for (final item in pending) {
      try {
        final localPendingId = item['localPendingId']?.toString();

        if (localPendingId == null || localPendingId.isEmpty) {
          continue;
        }

        final imagePath = item['imagePath']?.toString();

        if (imagePath == null || imagePath.isEmpty) {
          debugPrint('SYNC SKIPPED: image path missing');
          continue;
        }

        final imageFile = File(imagePath);

        if (!await imageFile.exists()) {
          debugPrint('SYNC SKIPPED: image not found $imagePath');
          continue;
        }

        final completedIdsRaw = item['completedSolutionIds'];
        final completedIds = completedIdsRaw is List
            ? completedIdsRaw
                .map((e) => int.tryParse(e.toString()))
                .whereType<int>()
                .toList()
            : <int>[];

        final draft = InspectionDraft(
          localId: localPendingId,
          deviceId: item['deviceId'].toString(),
          deviceCode: item['deviceCode']?.toString() ?? '',
          result: item['result']?.toString() ??
              (item['inspectionStatus'] == 'OK' ? 'good' : 'faulty'),
          notes: item['notes']?.toString() ?? '',
          imagePath: imagePath,
          latitude: (item['latitude'] as num?)?.toDouble() ?? 0,
          longitude: (item['longitude'] as num?)?.toDouble() ?? 0,
          createdAt: DateTime.tryParse(
                item['createdOfflineAt']?.toString() ?? '',
              ) ??
              DateTime.now(),
          inspectorId: item['technicianId'].toString(),
          isGood: item['isGood'] == true,
          issueId: item['issueId'] is num
              ? (item['issueId'] as num).toInt()
              : int.tryParse(item['issueId']?.toString() ?? ''),
          issueCode: item['issueCode']?.toString(),
          issueTitle: item['issueTitle']?.toString(),
          completedSolutionIds: completedIds,
          deviceTypeId: item['deviceTypeId'] is num
              ? (item['deviceTypeId'] as num).toInt()
              : int.tryParse(item['deviceTypeId']?.toString() ?? ''),
        );

        await _sendInspectionOnline(
          draft: draft,
          parsedDeviceId: int.parse(draft.deviceId),
          parsedTechnicianId: int.parse(draft.inspectorId),
          mappedStatus: item['inspectionStatus']?.toString() ?? 'OK',
          fullNotes: item['notes']?.toString() ?? '',
        );

        await _offline.removePendingInspection(localPendingId);

        synced++;
      } catch (e) {
        debugPrint('SYNC PENDING ITEM ERROR: $e');
      }
    }

    return synced;
  }

  Future<int> pendingOfflineCount() {
    return _offline.pendingCount();
  }

  Future<List<PendingSyncItem>> getPendingSyncItems() async {
    final pending = await _offline.getPendingInspections();

    return pending.map((item) {
      final createdAtRaw = item['createdOfflineAt']?.toString() ?? '';
      final createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();

      final imagePath = item['imagePath']?.toString() ?? '';
      double sizeMb = 0;

      if (imagePath.isNotEmpty) {
        try {
          final file = File(imagePath);

          if (file.existsSync()) {
            sizeMb = file.lengthSync() / (1024 * 1024);
          }
        } catch (_) {
          sizeMb = 0;
        }
      }

      return PendingSyncItem(
        localId: item['localPendingId']?.toString() ?? '',
        deviceName: item['deviceCode']?.toString() ??
            item['deviceId']?.toString() ??
            'Unknown Device',
        location: item['locationText']?.toString() ??
            item['notes']?.toString() ??
            '',
        sizeMb: sizeMb,
        queuedAt: createdAt,
        isFailed: (item['syncStatus']?.toString() ?? '').toUpperCase() ==
            'FAILED',
      );
    }).toList();
  }

  Future<List<ReportModel>> getOfflinePendingReports({
    required String technicianId,
    required String technicianName,
  }) async {
    final pending = await _offline.getPendingInspections();

    final reports = pending.map((item) {
      final createdAtRaw = item['createdOfflineAt']?.toString() ?? '';
      final createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();

      final inspectionStatus = item['inspectionStatus']?.toString() ?? 'OK';
      final result = _mapInspectionResult(inspectionStatus);

      final deviceCode = item['deviceCode']?.toString() ??
          item['deviceId']?.toString() ??
          '';

      final notes = item['notes']?.toString() ?? '';
      final issueCode = item['issueCode']?.toString();
      final issueTitle = item['issueTitle']?.toString();

      final fullNotes = [
        'محفوظ محليًا — في انتظار المزامنة',
        if (notes.trim().isNotEmpty) notes.trim(),
        if (issueCode != null && issueCode.trim().isNotEmpty)
          'Issue Code: $issueCode',
        if (issueTitle != null && issueTitle.trim().isNotEmpty)
          'Issue Title: $issueTitle',
      ].join('\n');

      return ReportModel(
        id: item['localPendingId']?.toString() ??
            'OFFLINE-${createdAt.millisecondsSinceEpoch}',
        reportNumber: 'OFFLINE-${createdAt.millisecondsSinceEpoch}',
        deviceId: item['deviceId']?.toString() ?? '',
        deviceName: deviceCode.isNotEmpty ? deviceCode : 'Offline Device',
        deviceType: 'access_control',
        deviceCode: deviceCode,
        locationText: item['locationText']?.toString() ?? fullNotes,
        building: '',
        floor: '',
        result: result,
        notes: fullNotes,
        inspectorName: technicianName,
        inspectorId: technicianId,
        latitude: (item['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (item['longitude'] as num?)?.toDouble() ?? 0,
        createdAt: createdAt,
        imageUrl: item['imagePath']?.toString(),
      );
    }).toList();

    reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return reports;
  }

  Future<void> syncNow() async {
    try {
      await refreshOfflineCache();
      await syncPendingInspections();

      try {
        await _dio.post(ApiConstants.syncPush);
        await _dio.get(ApiConstants.syncPull);
      } catch (e) {
        debugPrint('OPTIONAL SYNC ENDPOINTS SKIPPED: $e');
      }
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        debugPrint(
          'SYNC SKIPPED: sync endpoints are not implemented on backend yet',
        );
        return;
      }

      debugPrint('SYNC ERROR: ${error.response?.data ?? error.message}');
    }
  }

  Future<void> _syncIssueFlowInBackground({
    required int inspectionId,
    required InspectionDraft draft,
    required String notes,
  }) async {
    try {
      final int? parsedInspectorId = int.tryParse(draft.inspectorId.trim());

      if (parsedInspectorId == null) {
        debugPrint('ISSUE FLOW: skipped, invalid inspectorId');
        return;
      }

      if (draft.issueId == null) {
        debugPrint('ISSUE FLOW: skipped, no issueId');
        return;
      }

      final response = await _dio.post(
        _inspectionIssueReportPath,
        data: {
          'inspectionId': inspectionId,
          'issueId': draft.issueId,
          'reportedById': parsedInspectorId,
          'notes': notes,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 25),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final issueRaw = unwrapMap(response.data);
      final int? inspectionIssueId = (issueRaw['id'] as num?)?.toInt();

      if (inspectionIssueId == null) {
        debugPrint('ISSUE FLOW: no inspectionIssueId returned');
        return;
      }

      for (final solutionId in draft.completedSolutionIds) {
        try {
          await _dio.post(
            _inspectionIssueActionPath,
            data: {
              'inspectionId': inspectionId,
              'inspectionIssueId': inspectionIssueId,
              'solutionId': solutionId,
              'technicianId': parsedInspectorId,
              'status': 'DONE',
              'note': 'Completed from mobile inspection',
            },
            options: Options(
              sendTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 25),
            ),
          );

          debugPrint(
            'ISSUE FLOW ACTION DONE: inspectionIssueId=$inspectionIssueId solutionId=$solutionId',
          );
        } catch (e) {
          debugPrint(
            'ISSUE FLOW ACTION ERROR: solutionId=$solutionId -> $e',
          );
        }
      }

      try {
        await _dio.patch(
          '$_inspectionIssueItemBase/$inspectionIssueId/status',
          data: {
            'status': 'IN_PROGRESS',
            'notes': notes,
          },
          options: Options(
            sendTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 25),
          ),
        );
      } catch (e) {
        debugPrint(
          'ISSUE FLOW STATUS ERROR: inspectionIssueId=$inspectionIssueId -> $e',
        );
      }

      debugPrint(
        'ISSUE FLOW FINISHED: inspectionId=$inspectionId inspectionIssueId=$inspectionIssueId',
      );
    } catch (e) {
      debugPrint('ISSUE FLOW BACKGROUND ERROR -> $e');
    }
  }

  TaskNotificationModel _mapTask(Map<String, dynamic> json) {
    final device = json['device'] as Map<String, dynamic>? ?? {};
    final location = device['location'] as Map<String, dynamic>? ?? {};

    return TaskNotificationModel(
      id: json['id']?.toString() ?? '',
      deviceId: device['id']?.toString() ?? '',
      deviceName: device['deviceName']?.toString() ?? '',
      deviceCode: device['deviceCode']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      scheduledDate: DateTime.tryParse(json['scheduledDate']?.toString() ?? ''),
      cluster: location['cluster']?.toString() ?? '',
      building: location['building']?.toString() ?? '',
      zone: location['zone']?.toString() ?? '',
      lane: location['lane']?.toString() ?? '',
      direction: location['direction']?.toString() ?? '',
    );
  }

  DeviceModel _mapDevice(Map<String, dynamic> json) {
    final deviceType = json['deviceType'] as Map<String, dynamic>? ?? {};
    final location = json['location'] as Map<String, dynamic>? ?? {};

    final inspections = json['inspections'] is List
        ? json['inspections'] as List
        : const [];

    final lastInspection = inspections.isNotEmpty
        ? inspections.first as Map<String, dynamic>
        : (json['lastInspection'] as Map<String, dynamic>? ?? {});

    final technician =
        lastInspection['technician'] as Map<String, dynamic>? ?? {};

    final images = lastInspection['images'] as List? ?? [];
    final status = json['currentStatus']?.toString() ?? 'OK';

    return DeviceModel(
      id: json['id']?.toString() ?? '',
      code: json['deviceCode']?.toString() ?? '',
      name: json['deviceName']?.toString() ?? '',
      type: _mapDeviceType(deviceType['name']?.toString()),
      brand: json['manufacturer']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      serialNumber: json['serialNumber']?.toString() ?? '',
      ipAddress: json['ipAddress']?.toString() ?? '',
      firmware: json['firmware']?.toString() ?? '',
      modelNumber: json['modelNumber']?.toString() ?? '',
      notes: _buildDeviceNotes(json, lastInspection),
      location: _buildLocation(location),
      building: location['building']?.toString() ?? '',
      floor: location['zone']?.toString() ?? '',
      room: location['lane']?.toString() ?? '',
      status: _mapDeviceStatus(status),
      lastInspectorName: technician['fullName']?.toString() ??
          technician['username']?.toString() ??
          technician['email']?.toString(),
      lastInspectionDate: DateTime.tryParse(
        lastInspection['inspectedAt']?.toString() ??
            json['lastInspectionAt']?.toString() ??
            '',
      ),
      latitude: (lastInspection['latitude'] as num?)?.toDouble(),
      longitude: (lastInspection['longitude'] as num?)?.toDouble(),
      imageUrl: images.isNotEmpty
          ? (images.first as Map<String, dynamic>)['imageUrl']?.toString()
          : null,
      backendDeviceTypeId: (deviceType['id'] as num?)?.toInt(),
      backendDeviceTypeName: deviceType['name']?.toString(),
      backendCategoryName: _inferCategoryName(deviceType['name']?.toString()),
    );
  }

  String _buildDeviceNotes(
    Map<String, dynamic> deviceJson,
    Map<String, dynamic> lastInspection,
  ) {
    final inspectionNotes = lastInspection['notes']?.toString() ?? '';
    final issueReason = lastInspection['issueReason']?.toString() ?? '';
    final deviceNotes = deviceJson['notes']?.toString() ?? '';

    final lines = <String>[
      if (inspectionNotes.trim().isNotEmpty) inspectionNotes.trim(),
      if (issueReason.trim().isNotEmpty) 'Issue Reason: ${issueReason.trim()}',
      if (deviceNotes.trim().isNotEmpty) 'Device Notes: ${deviceNotes.trim()}',
    ];

    return lines.join('\n');
  }

  ReportModel _mapInspectionToReport(Map<String, dynamic> json) {
    final device = json['device'] as Map<String, dynamic>? ?? {};
    final location = device['location'] as Map<String, dynamic>? ?? {};
    final technician = json['technician'] as Map<String, dynamic>? ?? {};
    final images = json['images'] as List? ?? [];

    return ReportModel(
      id: json['id']?.toString() ?? '',
      reportNumber: json['reportNumber']?.toString() ??
          'RPT-${json['id']?.toString() ?? ''}',
      deviceId: device['id']?.toString() ?? '',
      deviceName:
          device['deviceName']?.toString() ?? device['name']?.toString() ?? '',
      deviceType: _mapDeviceType(
        (device['deviceType'] as Map<String, dynamic>?)?['name']?.toString(),
      ),
      deviceCode: device['deviceCode']?.toString() ??
          device['barcode']?.toString() ??
          '',
      locationText: _buildLocation(location),
      building: location['building']?.toString() ?? '',
      floor: location['zone']?.toString() ?? '',
      result: _mapInspectionResult(
        json['inspectionStatus']?.toString() ?? 'OK',
      ),
      notes: json['notes']?.toString() ?? '',
      inspectorName: technician['fullName']?.toString() ??
          technician['username']?.toString() ??
          technician['email']?.toString() ??
          '',
      inspectorId: technician['id']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(
            json['inspectedAt']?.toString() ??
                json['createdAt']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      imageUrl: images.isNotEmpty
          ? (images.first as Map<String, dynamic>)['imageUrl']?.toString()
          : null,
    );
  }

  String _buildInspectionNotes(InspectionDraft draft) {
    final lines = <String>[
      if (draft.notes.trim().isNotEmpty) draft.notes.trim(),
      'الحالة النهائية: ${draft.result}',
      if (draft.isGood)
        'Final Device Condition: OK'
      else
        'Final Device Condition: NOT_OK',
      if (draft.issueCode != null && draft.issueCode!.trim().isNotEmpty)
        'Main Issue Code: ${draft.issueCode}',
      if (draft.issueTitle != null && draft.issueTitle!.trim().isNotEmpty)
        'Main Issue Title: ${draft.issueTitle}',
      if (draft.completedSolutionIds.isNotEmpty)
        'Completed Steps IDs: ${draft.completedSolutionIds.join(", ")}',
    ];

    return lines.where((line) => line.trim().isNotEmpty).join('\n');
  }

  int? _extractInspectionId(Map<String, dynamic> raw) {
    if (raw['id'] is num) return (raw['id'] as num).toInt();

    final data = raw['data'];

    if (data is Map<String, dynamic>) {
      if (data['id'] is num) return (data['id'] as num).toInt();
    }

    return null;
  }

  String _extractReportNumber(Map<String, dynamic> raw) {
    final direct =
        raw['reportNumber']?.toString() ?? raw['report_number']?.toString();

    if (direct != null && direct.isNotEmpty) return direct;

    final data = raw['data'];

    if (data is Map<String, dynamic>) {
      final nested =
          data['reportNumber']?.toString() ?? data['report_number']?.toString();

      if (nested != null && nested.isNotEmpty) return nested;
    }

    return 'RPT-${DateTime.now().millisecondsSinceEpoch}';
  }

  String _mapInspectionStatus(String result) {
    switch (result.trim().toLowerCase()) {
      case 'good':
        return 'OK';
      case 'minor':
        return 'PARTIAL';
      case 'maintenance':
        return 'NOT_OK';
      case 'faulty':
        return 'NOT_OK';
      default:
        return 'NOT_REACHABLE';
    }
  }

  String _mapInspectionResult(String status) {
    switch (status.toUpperCase()) {
      case 'OK':
        return 'good';
      case 'PARTIAL':
        return 'minor';
      case 'NOT_OK':
        return 'maintenance';
      case 'NOT_REACHABLE':
        return 'review';
      default:
        return 'review';
    }
  }

  String _mapDeviceStatus(String status) {
    switch (status.toUpperCase()) {
      case 'OK':
        return 'good';
      case 'NEEDS_MAINTENANCE':
        return 'maintenance';
      case 'UNDER_MAINTENANCE':
        return 'maintenance';
      case 'OUT_OF_SERVICE':
        return 'faulty';
      default:
        return 'review';
    }
  }

  String _mapDeviceType(String? name) {
    final value = (name ?? '').toLowerCase();

    if (value.contains('printer')) return 'printer';
    if (value.contains('camera')) return 'camera';
    if (value.contains('projector')) return 'projector';
    if (value.contains('scanner')) return 'scanner';
    if (value.contains('laptop')) return 'laptop';

    if (value.contains('reader')) return 'access_control';
    if (value.contains('controller')) return 'access_control';
    if (value.contains('morpho')) return 'access_control';
    if (value.contains('argus')) return 'access_control';
    if (value.contains('access')) return 'access_control';

    return 'computer';
  }

  String _inferCategoryName(String? deviceTypeName) {
    final value = (deviceTypeName ?? '').toLowerCase();

    if (value.contains('argus') || value.contains('gate')) {
      return 'Gates';
    }

    return 'Access Control';
  }

  int? _resolveIssueDeviceTypeId(DeviceModel device) {
    if (device.backendDeviceTypeId != null && device.backendDeviceTypeId! > 0) {
      return device.backendDeviceTypeId;
    }

    final blob = [
      device.backendDeviceTypeName,
      device.type,
      device.name,
      device.brand,
      device.modelNumber,
      device.code,
      device.notes,
    ].whereType<String>().join(' ').toLowerCase();

    if (blob.contains('argus')) return 140;
    if (blob.contains('reader')) return 2;
    if (blob.contains('controller')) return 3;
    if (blob.contains('morpho')) return 4;
    if (blob.contains('access')) return 1;

    return null;
  }

  String _buildLocation(Map<String, dynamic> location) {
    final parts = [
      location['cluster']?.toString(),
      location['building']?.toString(),
      location['zone']?.toString(),
      location['lane']?.toString(),
      location['direction']?.toString(),
    ].where((part) => part != null && part.isNotEmpty).toList();

    return parts.join(' - ');
  }
}