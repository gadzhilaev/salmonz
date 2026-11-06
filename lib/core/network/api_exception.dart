import 'package:dio/dio.dart';

/// Normalized API / network error for UI and repositories.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.isNetworkError = false,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final bool isNetworkError;

  /// Safe message for UI (never raw Dio/Socket/stack traces).
  String get userMessage => message;

  bool get isNetwork => isNetworkError;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;

  /// Wrong email/password (login) — not the same as mid-session expiry.
  bool get isInvalidCredentials {
    final lower = message.toLowerCase();
    return statusCode == 401 &&
        (lower.contains('неверный email') ||
            lower.contains('invalid credentials') ||
            code?.toLowerCase() == 'unauthorized');
  }

  static const connectionMessage = 'Нет соединения с сервером';
  static const timeoutMessage = 'Превышено время ожидания сервера';
  static const genericMessage = 'Произошла ошибка';
  static const invalidCredentialsMessage = 'Неверный email или пароль';
  static const sessionExpiredMessage = 'Сессия истекла. Войдите снова';

  /// User-facing text for any thrown object.
  static String userMessageFrom(Object error) =>
      ApiException.fromError(error).userMessage;

  factory ApiException.fromError(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) return ApiException.fromDio(error);
    return const ApiException(message: genericMessage);
  }

  factory ApiException.fromDio(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final path = e.requestOptions.path;

    var message = _sanitizeMessage(e.message);
    String? code;
    var isNetwork = false;

    if (data is Map) {
      final msg = data['message'];
      if (msg is String && msg.trim().isNotEmpty) {
        message = msg;
      } else if (msg is List && msg.isNotEmpty) {
        message = msg.map((item) => item.toString()).join(', ');
      }
      final c = data['error'] ?? data['code'];
      if (c != null) code = c.toString();
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = timeoutMessage;
        isNetwork = true;
        break;
      case DioExceptionType.connectionError:
        message = connectionMessage;
        isNetwork = true;
        break;
      case DioExceptionType.cancel:
        message = 'Запрос отменён';
        break;
      default:
        if (status == null && _looksLikeNetworkFailure(e, message)) {
          message = connectionMessage;
          isNetwork = true;
        } else if (_isTechnicalMessage(message)) {
          message = status != null ? 'Ошибка сервера' : connectionMessage;
          if (status == null) isNetwork = true;
        }
        break;
    }

    if (!isNetwork && status == 401) {
      message = _mapUnauthorizedMessage(raw: message, path: path, code: code);
    } else if (status != null && status >= 500) {
      message = 'Ошибка сервера';
    } else {
      message = _mapKnownApiMessage(message);
    }

    return ApiException(
      message: message,
      statusCode: status,
      code: code,
      isNetworkError: isNetwork,
    );
  }

  /// Never expose "Требуется авторизация" for expected auth flows.
  static String _mapUnauthorizedMessage({
    required String raw,
    required String path,
    String? code,
  }) {
    final lower = raw.toLowerCase();
    final pathLower = path.toLowerCase();

    if (lower.contains('invalid credentials') ||
        pathLower.contains('/auth/login')) {
      return invalidCredentialsMessage;
    }
    if (lower.contains('refresh') || pathLower.contains('/auth/refresh')) {
      return sessionExpiredMessage;
    }
    if (pathLower.contains('/auth/register')) {
      return _mapKnownApiMessage(raw);
    }
    // Mid-session 401 after failed refresh / protected call.
    return sessionExpiredMessage;
  }

  static String _mapKnownApiMessage(String raw) {
    final lower = raw.toLowerCase().trim();
    if (lower.contains('invalid credentials')) {
      return invalidCredentialsMessage;
    }
    if (lower.contains('email') &&
        (lower.contains('already') || lower.contains('exists')) &&
        !lower.contains(',')) {
      return 'Этот email уже зарегистрирован';
    }
    if ((lower == 'password too short' ||
            lower.startsWith('password must be')) &&
        !lower.contains(',')) {
      return 'Пароль должен быть не короче 8 символов';
    }
    if (_isTechnicalMessage(raw) || raw.trim().isEmpty) {
      return genericMessage;
    }
    return raw;
  }

  static String _sanitizeMessage(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    if (_isTechnicalMessage(raw)) return '';
    return raw;
  }

  static bool _isTechnicalMessage(String message) {
    final lower = message.toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('dioexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('network is unreachable') ||
        lower.contains('software caused connection abort') ||
        message.contains('Exception:') ||
        message.contains('Error:');
  }

  static bool _looksLikeNetworkFailure(DioException e, String message) {
    if (e.error != null) {
      final err = e.error.toString().toLowerCase();
      if (err.contains('socket') ||
          err.contains('connection') ||
          err.contains('network')) {
        return true;
      }
    }
    return message.isEmpty || _isTechnicalMessage(message);
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
