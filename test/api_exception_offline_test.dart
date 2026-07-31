import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salmonz/core/network/api_exception.dart';

void main() {
  group('ApiException offline / network mapping', () {
    test('maps connectionError to friendly Russian', () {
      final e = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError,
          message: 'SocketException: Failed host lookup',
          error: const SocketException('Failed host lookup'),
        ),
      );

      expect(e.message, 'Нет соединения с сервером');
      expect(e.userMessage, 'Нет соединения с сервером');
      expect(e.isNetwork, isTrue);
      expect(e.message, isNot(contains('SocketException')));
      expect(e.message, isNot(contains('DioException')));
    });

    test('maps connectionTimeout to friendly Russian', () {
      final e = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionTimeout,
          message: 'Connecting timed out',
        ),
      );

      expect(e.message, 'Превышено время ожидания сервера');
      expect(e.isNetwork, isTrue);
    });

    test('maps receiveTimeout and sendTimeout', () {
      for (final type in [
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
      ]) {
        final e = ApiException.fromDio(
          DioException(
            requestOptions: RequestOptions(path: '/x'),
            type: type,
          ),
        );
        expect(e.message, 'Превышено время ожидания сервера');
        expect(e.isNetwork, isTrue);
      }
    });

    test('isUnauthorized is true for 401', () {
      final e = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          response: Response(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: 401,
            data: const {'message': 'Unauthorized'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(e.isUnauthorized, isTrue);
      expect(e.isNetwork, isFalse);
      expect(e.userMessage, 'Требуется авторизация');
      expect(e.userMessage, isNot(contains('Unauthorized')));
    });

    test('maps 500 responses to a safe Russian message', () {
      final e = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          response: Response(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: 500,
            data: const {'message': 'Internal server error'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(e.userMessage, 'Ошибка сервера');
      expect(e.userMessage, isNot(contains('Internal server error')));
    });

    test('userMessageFrom never exposes raw Dio errors', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionError,
        message: 'DioException [connection error]: SocketException',
      );
      final text = ApiException.userMessageFrom(dio);

      expect(text, 'Нет соединения с сервером');
      expect(text, isNot(contains('DioException')));
    });

    test('userMessageFrom returns generic message for unknown errors', () {
      expect(
        ApiException.userMessageFrom(Exception('boom')),
        'Произошла ошибка',
      );
    });
  });
}
