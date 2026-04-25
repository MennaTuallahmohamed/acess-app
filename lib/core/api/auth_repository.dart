import 'package:access_track/app_constants.dart';
import 'package:access_track/core/api/api_client.dart';
import 'package:access_track/core/modals/models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiDioProvider),
    ref.watch(secureStorageProvider),
  );
});

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepository(this._dio, this._storage);

  Future<UserModel?> restoreSession() async {
    final rawUser = await _storage.read(key: StorageKeys.userData);
    final token = await _storage.read(key: StorageKeys.accessToken);

    if (rawUser == null || token == null || token.isEmpty) {
      return null;
    }

    final user = _parseUser(
      decodeJsonMap(rawUser),
      tokenOverride: token,
    );

    return user.id.isEmpty ? null : user;
  }

  Future<UserModel> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final raw = unwrapMap(response.data);

      final token = raw['token']?.toString() ??
          raw['accessToken']?.toString() ??
          raw['access_token']?.toString() ??
          '';

      final userJson = raw['user'] ?? raw;
      UserModel user = _parseUser(userJson, tokenOverride: token);

      if (user.id.isEmpty) {
        throw const ApiException('تم تسجيل الدخول لكن بيانات المستخدم غير مكتملة');
      }

      if (user.role.isEmpty) {
        user = UserModel(
          id: user.id,
          email: user.email,
          name: user.name,
          role: role.toLowerCase(),
          region: user.region,
          avatarUrl: user.avatarUrl,
          totalInspections: user.totalInspections,
          monthInspections: user.monthInspections,
          completionRate: user.completionRate,
          token: user.token,
        );
      }

      await _storage.write(key: StorageKeys.accessToken, value: user.token);
      await _storage.write(key: StorageKeys.userId, value: user.id);
      await _storage.write(
        key: StorageKeys.userData,
        value: encodeJson(user.toJson()),
      );
      await _storage.write(key: 'selected_role', value: role.toLowerCase());

      return user;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
    } on DioException {
    } finally {
      await _storage.delete(key: StorageKeys.accessToken);
      await _storage.delete(key: StorageKeys.userId);
      await _storage.delete(key: StorageKeys.userData);
      await _storage.delete(key: 'selected_role');
    }
  }

  UserModel _parseUser(
    dynamic rawJson, {
    String? tokenOverride,
  }) {
    final json = unwrapMap(rawJson);

    final roleValue = json['role'];
    String roleName = '';

    if (roleValue is Map) {
      roleName = roleValue['name']?.toString() ?? '';
    } else {
      roleName = roleValue?.toString() ?? '';
    }

    final firstName = json['firstName']?.toString() ?? '';
    final lastName = json['lastName']?.toString() ?? '';
    final fullName = json['fullName']?.toString() ??
        json['name']?.toString() ??
        '$firstName $lastName'.trim();

    final employeeId = json['email']?.toString() ?? '';

    return UserModel(
      id: json['id']?.toString() ?? '',
      email: employeeId,
      name: fullName.isEmpty ? employeeId : fullName,
      role: roleName.toLowerCase(),
      region: json['region']?.toString() ?? '',
      avatarUrl:
          json['avatar_url']?.toString() ?? json['avatarUrl']?.toString(),
      totalInspections: (json['total_inspections'] as num?)?.toInt() ??
          (json['totalInspections'] as num?)?.toInt() ??
          0,
      monthInspections: (json['month_inspections'] as num?)?.toInt() ??
          (json['monthInspections'] as num?)?.toInt() ??
          0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ??
          (json['completionRate'] as num?)?.toDouble() ??
          0,
      token: tokenOverride?.isNotEmpty == true
          ? tokenOverride!
          : json['token']?.toString() ??
              json['accessToken']?.toString() ??
              json['access_token']?.toString() ??
              '',
    );
  }
}