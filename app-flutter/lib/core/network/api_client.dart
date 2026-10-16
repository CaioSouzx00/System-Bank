import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/env_config.dart';
import '../errors/app_exception.dart';
import '../storage/cache_storage_service.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorageService secureStorage;
  final CacheStorageService cacheStorage;
  final VoidCallback? onUnauthorized;

  ApiClient({
    required this.secureStorage,
    required this.cacheStorage,
    this.onUnauthorized,
  }) {
    final customUrl = cacheStorage.getCustomBaseUrl();
    final baseUrl = (customUrl != null && customUrl.isNotEmpty)
        ? customUrl
        : EnvConfig.defaultBaseUrl;

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: EnvConfig.connectTimeout,
        receiveTimeout: EnvConfig.receiveTimeout,
        sendTimeout: EnvConfig.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Auth Interceptor
    dio.interceptors.add(
      AuthInterceptor(
        storageService: secureStorage,
        onUnauthorized: onUnauthorized,
      ),
    );

    // Logging em modo debug
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          requestHeader: false,
          responseHeader: false,
        ),
      );
    }
  }

  void updateBaseUrl(String newUrl) {
    dio.options.baseUrl = newUrl;
    cacheStorage.setCustomBaseUrl(newUrl);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.get<T>(path, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }
}
