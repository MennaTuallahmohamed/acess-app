import 'dart:async';

import 'package:access_track/core/api/auth_repository.dart';
import 'package:access_track/core/api/technician_repository.dart';
import 'package:access_track/core/modals/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserModel?>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).valueOrNull;
});

final technicianOnlineReportsProvider =
    FutureProvider.autoDispose<List<ReportModel>>((ref) async {
  final user = ref.watch(currentUserProvider);

  if (user == null || user.role.toLowerCase() != 'technician') {
    return [];
  }

  final reports =
      await ref.watch(technicianRepositoryProvider).getMyReports(user.id);

  return reports..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

final technicianOfflineReportsProvider =
    FutureProvider.autoDispose<List<ReportModel>>((ref) async {
  final user = ref.watch(currentUserProvider);

  if (user == null || user.role.toLowerCase() != 'technician') {
    return [];
  }

  final reports = await ref
      .watch(technicianRepositoryProvider)
      .getOfflinePendingReports(
        technicianId: user.id,
        technicianName: user.name,
      );

  return reports..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

final technicianReportsProvider =
    FutureProvider.autoDispose<List<ReportModel>>((ref) async {
  final online = await ref.watch(technicianOnlineReportsProvider.future);
  final offline = await ref.watch(technicianOfflineReportsProvider.future);

  final merged = <ReportModel>[
    ...offline,
    ...online,
  ];

  merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return merged;
});

final allReportsProvider = technicianReportsProvider;

final todayStatsProvider = FutureProvider.autoDispose<TodayStats>((ref) async {
  final reports = await ref.watch(technicianReportsProvider.future);
  final now = DateTime.now();

  final todayReports = reports.where((report) {
    final createdAt = report.createdAt;

    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }).toList();

  int countByResult(String result) {
    return todayReports.where((report) => report.result == result).length;
  }

  return TodayStats(
    totalInspected: todayReports.length,
    good: countByResult('good'),
    needsMaintenance: countByResult('maintenance') +
        countByResult('minor') +
        countByResult('faulty'),
    underReview: countByResult('review'),
  );
});

final recentInspectionsProvider =
    FutureProvider.autoDispose<List<ReportModel>>((ref) async {
  final reports = await ref.watch(technicianReportsProvider.future);
  return reports.take(5).toList();
});

final dashboardProvider = Provider<int>((ref) => 0);

final deviceScanProvider =
    StateNotifierProvider<DeviceScanController, AsyncValue<DeviceModel?>>((ref) {
  return DeviceScanController(ref.watch(technicianRepositoryProvider));
});

final inspectionSubmitProvider = StateNotifierProvider<
    InspectionSubmitController, AsyncValue<InspectionSubmissionResult?>>((ref) {
  return InspectionSubmitController(ref.watch(technicianRepositoryProvider));
});

final syncProvider =
    StateNotifierProvider<SyncController, SyncStatusModel>((ref) {
  return SyncController(
    ref.watch(technicianRepositoryProvider),
    ref,
  );
});

class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AsyncValue.loading()) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final user = await _repository.restoreSession();
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<bool> login(String email, String password, String role) async {
    state = const AsyncValue.loading();

    try {
      final user = await _repository.login(
        email: email,
        password: password,
        role: role,
      );

      state = AsyncValue.data(user);
      return true;
    } catch (_) {
      state = const AsyncValue.data(null);
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }
}

class DeviceScanController extends StateNotifier<AsyncValue<DeviceModel?>> {
  final TechnicianRepository _repository;

  DeviceScanController(this._repository) : super(const AsyncValue.data(null));

  Future<bool> scan(String code) async {
    state = const AsyncValue.loading();

    try {
      final device = await _repository.getDeviceByCode(code);
      state = AsyncValue.data(device);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  Future<bool> scanSecretCode(String secretCode) async {
    state = const AsyncValue.loading();

    try {
      final device = await _repository.getDeviceBySecretCode(secretCode);
      state = AsyncValue.data(device);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

class InspectionSubmitController
    extends StateNotifier<AsyncValue<InspectionSubmissionResult?>> {
  final TechnicianRepository _repository;

  InspectionSubmitController(this._repository)
      : super(const AsyncValue.data(null));

  Future<InspectionSubmissionResult> submit(InspectionDraft draft) async {
    state = const AsyncValue.loading();

    try {
      final result = await _repository.submitInspection(draft);
      state = AsyncValue.data(result);
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

class SyncController extends StateNotifier<SyncStatusModel> {
  final TechnicianRepository _repository;
  final Ref _ref;

  Timer? _retryTimer;
  bool _isSyncing = false;

  SyncController(this._repository, this._ref) : super(_initialState()) {
    Future.microtask(() async {
      await refreshOnly();

      if (state.pending > 0) {
        await syncNow();
      } else {
        _refreshReportProviders();
      }
    });

    _retryTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) async {
        await _syncIfPending();
      },
    );
  }

  static SyncStatusModel _initialState() {
    return SyncStatusModel(
      isConnected: true,
      synced: 0,
      pending: 0,
      failed: 0,
      lastSyncTime: DateTime.now(),
      pendingItems: const [],
    );
  }

  void _refreshReportProviders() {
    _ref.invalidate(technicianOfflineReportsProvider);
    _ref.invalidate(technicianOnlineReportsProvider);
    _ref.invalidate(technicianReportsProvider);
    _ref.invalidate(allReportsProvider);
    _ref.invalidate(todayStatsProvider);
    _ref.invalidate(recentInspectionsProvider);
  }

  Future<void> refreshOnly({
    bool isConnected = true,
    int synced = 0,
    int failed = 0,
    DateTime? lastSyncTime,
  }) async {
    final pending = await _repository.pendingOfflineCount();
    final pendingItems = await _repository.getPendingSyncItems();

    state = SyncStatusModel(
      isConnected: isConnected,
      synced: synced,
      pending: pending,
      failed: failed,
      lastSyncTime: lastSyncTime ?? state.lastSyncTime,
      pendingItems: pendingItems,
    );

    _refreshReportProviders();
  }

  Future<void> syncNow() async {
    if (_isSyncing) return;

    _isSyncing = true;

    try {
      await _repository.refreshOfflineCache();

      final syncedCount = await _repository.syncPendingInspections();
      final pendingAfterSync = await _repository.pendingOfflineCount();
      final pendingItems = await _repository.getPendingSyncItems();

      state = SyncStatusModel(
        isConnected: true,
        synced: syncedCount,
        pending: pendingAfterSync,
        failed: 0,
        lastSyncTime: DateTime.now(),
        pendingItems: pendingItems,
      );

      _refreshReportProviders();
    } catch (_) {
      final pending = await _repository.pendingOfflineCount();
      final pendingItems = await _repository.getPendingSyncItems();

      state = SyncStatusModel(
        isConnected: false,
        synced: 0,
        pending: pending,
        failed: pending,
        lastSyncTime: state.lastSyncTime,
        pendingItems: pendingItems,
      );

      _refreshReportProviders();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncIfPending() async {
    if (_isSyncing) return;

    final pending = await _repository.pendingOfflineCount();

    if (pending <= 0) {
      await refreshOnly();
      return;
    }

    await syncNow();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }
}