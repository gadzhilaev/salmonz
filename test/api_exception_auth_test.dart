import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salmonz/core/network/api_exception.dart';

DioException _dio({
  required int? status,
  Object? data,
  String path = '/auth/login',
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  return DioException(
    requestOptions: RequestOptions(path: path),
    type: type,
    response: status == null
        ? null
        : Response(
            requestOptions: RequestOptions(path: path),
            statusCode: status,
            data: data,
          ),
  );
}

void main() {
  test('login 401 Invalid credentials → friendly password error', () {
    final e = ApiException.fromDio(
      _dio(
        status: 401,
        data: {
          'statusCode': 401,
          'error': 'Unauthorized',
          'message': 'Invalid credentials',
        },
        path: '/auth/login',
      ),
    );
    expect(e.message, ApiException.invalidCredentialsMessage);
    expect(e.message.contains('Требуется авторизация'), isFalse);
    expect(e.isUnauthorized, isTrue);
  });

  test('protected 401 → session expired, not auth-required toast copy', () {
    final e = ApiException.fromDio(
      _dio(status: 401, data: {'message': 'Unauthorized'}, path: '/orders'),
    );
    expect(e.message, ApiException.sessionExpiredMessage);
    expect(e.message.contains('Требуется авторизация'), isFalse);
  });

  test('refresh 401 reuse → session expired', () {
    final e = ApiException.fromDio(
      _dio(
        status: 401,
        data: {'message': 'Refresh token reuse detected'},
        path: '/auth/refresh',
      ),
    );
    expect(e.message, ApiException.sessionExpiredMessage);
  });

  test('network error is not treated as session expiry', () {
    final e = ApiException.fromDio(
      _dio(
        status: null,
        path: '/auth/login',
        type: DioExceptionType.connectionError,
      ),
    );
    expect(e.isNetwork, isTrue);
    expect(e.message, ApiException.connectionMessage);
    expect(e.isUnauthorized, isFalse);
  });

  test('500 → server error', () {
    final e = ApiException.fromDio(
      _dio(status: 500, data: {'message': 'boom'}, path: '/orders'),
    );
    expect(e.message, 'Ошибка сервера');
  });
}
