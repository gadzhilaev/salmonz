import 'package:dio/dio.dart';

/// Normalized API / network error for UI and repositories.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
  });

  final String message;
  final int? statusCode;
  final String? code;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;

  factory ApiException.fromDio(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    String message = e.message ?? 'Network error';
    String? code;

    if (data is Map) {
      final msg = data['message'];
      if (msg is String && msg.trim().isNotEmpty) {
        message = msg;
      } else if (msg is List && msg.isNotEmpty) {
        message = msg.map((e) => e.toString()).join(', ');
      }
      final c = data['error'] ?? data['code'];
      if (c != null) code = c.toString();
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Превышено время ожидания сервера';
        break;
      case DioExceptionType.connectionError:
        message = 'Нет соединения с сервером';
        break;
      case DioExceptionType.cancel:
        message = 'Запрос отменён';
        break;
      default:
        break;
    }

    if (status == 401) {
      message = message.isEmpty || message == (e.message ?? '')
          ? 'Требуется авторизация'
          : message;
    }

    return ApiException(message: message, statusCode: status, code: code);
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
