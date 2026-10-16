import 'dart:async';
import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

typedef OnUnauthorizedCallback = void Function();

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storageService;
  final OnUnauthorizedCallback? onUnauthorized;

  AuthInterceptor({
    required SecureStorageService storageService,
    this.onUnauthorized,
  }) : _storageService = storageService;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Busca o JWT token no SecureStorage
    final token = await _storageService.getToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    options.headers['Accept'] = options.headers['Accept'] ?? 'application/json';
    options.headers['Content-Type'] = options.headers['Content-Type'] ?? 'application/json';

    return handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // 401 Unauthorized: token expirado ou inválido
    if (err.response?.statusCode == 401) {
      await _storageService.clearAuth();
      if (onUnauthorized != null) {
        onUnauthorized!();
      }
    }

    return handler.next(err);
  }
}
