import 'package:dio/dio.dart';

abstract class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const AppException(this.message, {this.statusCode, this.data});

  @override
  String toString() => message;

  factory AppException.fromDioError(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkTimeoutException('Tempo de conexão esgotado. Verifique seu sinal ou o servidor local.');
      case DioExceptionType.badResponse:
        final status = dioException.response?.statusCode;
        final responseData = dioException.response?.data;
        String errorMessage = 'Ocorreu um erro no servidor ($status)';

        if (responseData is Map && responseData.containsKey('error')) {
          errorMessage = responseData['error'].toString();
        } else if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        } else if (responseData is String && responseData.isNotEmpty) {
          errorMessage = responseData;
        }

        switch (status) {
          case 400:
            return BadRequestException(errorMessage, statusCode: 400, data: responseData);
          case 401:
            return UnauthorizedException(errorMessage, statusCode: 401, data: responseData);
          case 403:
            return ForbiddenException('Acesso negado: $errorMessage', statusCode: 403, data: responseData);
          case 404:
            return NotFoundException(errorMessage, statusCode: 404, data: responseData);
          case 409:
            return ConflictException(errorMessage, statusCode: 409, data: responseData);
          case 429:
            return RateLimitException('Limite de requisições excedido. Tente novamente em alguns segundos.', statusCode: 429);
          case 500:
          case 502:
          case 503:
            return ServerException(errorMessage, statusCode: status, data: responseData);
          default:
            return ServerException(errorMessage, statusCode: status, data: responseData);
        }
      case DioExceptionType.connectionError:
        return const ConnectionException('Não foi possível conectar ao servidor System-Bank (http://localhost:8080). Certifique-se de que o backend está ativo.');
      case DioExceptionType.cancel:
        return const AppException('Requisição cancelada.');
      default:
        return AppException('Erro de conexão inesperado: ${dioException.message}');
    }
  }
}

class NetworkTimeoutException extends AppException {
  const NetworkTimeoutException(super.message);
}

class ConnectionException extends AppException {
  const ConnectionException(super.message);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message, {super.statusCode, super.data});
}

class ForbiddenException extends AppException {
  const ForbiddenException(super.message, {super.statusCode, super.data});
}

class BadRequestException extends AppException {
  const BadRequestException(super.message, {super.statusCode, super.data});
}

class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.statusCode, super.data});
}

class ConflictException extends AppException {
  const ConflictException(super.message, {super.statusCode, super.data});
}

class RateLimitException extends AppException {
  const RateLimitException(super.message, {super.statusCode, super.data});
}

class ServerException extends AppException {
  const ServerException(super.message, {super.statusCode, super.data});
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}
