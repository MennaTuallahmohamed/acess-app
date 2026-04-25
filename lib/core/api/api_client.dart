import 'dart:convert';

import 'package:access_track/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final apiDioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: const {
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: StorageKeys.accessToken);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  dio.interceptors.add(
    PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      compact: true,
      maxWidth: 120,
    ),
  );

  return dio;
});

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  factory ApiException.fromDio(DioException error) {
    final responseData = error.response?.data;
    final fallbackMessage = error.message ?? 'Request failed';

    if (responseData is Map) {
      final dynamic rawMessage = responseData['message'];
      final message = rawMessage is List
          ? rawMessage.join('\n')
          : rawMessage?.toString() ??
              responseData['error']?.toString() ??
              responseData['details']?.toString() ??
              fallbackMessage;

      return ApiException(message, statusCode: error.response?.statusCode);
    }

    if (responseData is String && responseData.trim().isNotEmpty) {
      return ApiException(responseData, statusCode: error.response?.statusCode);
    }

    return ApiException(
      fallbackMessage,
      statusCode: error.response?.statusCode,
    );
  }

  @override
  String toString() => message;
}

Map<String, dynamic> unwrapMap(dynamic raw) {
  if (raw is Map && raw['data'] != null) {
    final data = raw['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.cast<String, dynamic>();
    }
  }

  if (raw is Map<String, dynamic>) {
    return raw;
  }

  if (raw is Map) {
    return raw.cast<String, dynamic>();
  }

  return <String, dynamic>{};
}

List<dynamic> unwrapList(dynamic raw) {
  if (raw is Map && raw['data'] is List) {
    return raw['data'] as List<dynamic>;
  }
  if (raw is List) {
    return raw;
  }
  return const [];
}

String encodeJson(Map<String, dynamic> value) => jsonEncode(value);

Map<String, dynamic> decodeJsonMap(String value) {
  final decoded = jsonDecode(value);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }
  if (decoded is Map) {
    return decoded.cast<String, dynamic>();
  }
  return <String, dynamic>{};
}