import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salmonz/core/money/money.dart';
import 'package:salmonz/core/network/api_exception.dart';
import 'package:salmonz/widgets/cart.dart';

void main() {
  group('Money', () {
    test('parses int/double/string and formats RUB', () {
      expect(Money.parse(100).format(), '100');
      expect(Money.parse(99.5).format(), '99,50');
      expect(Money.parse('1249.00').formatRub(), '1 249 ₽');
      expect(Money.parse(0).formatRub(), '0 ₽');
    });

    test('multiplication and addition use minor units', () {
      final a = Money.parse(10.5);
      final b = Money.parse('2');
      expect((a * 2).format(), '21');
      expect((a + b).format(), '12,50');
    });
  });

  group('ApiException', () {
    test('maps Dio response message', () {
      final e = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          response: Response(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: 400,
            data: {'message': 'Bad request'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      expect(e.statusCode, 400);
      expect(e.message, 'Bad request');
    });

    test('maps connection errors', () {
      final e = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError,
        ),
      );
      expect(e.message, contains('соединения'));
    });

    test('maps list validation messages', () {
      final e = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          response: Response(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: 400,
            data: {
              'message': ['email must be an email', 'password too short'],
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      expect(e.message, contains('email must be an email'));
    });
  });

  group('CartItem', () {
    test('subtotal uses Money minor units', () {
      final item = CartItem(
        id: 'p1',
        name: 'Roll',
        img: '',
        price: Money.parse(350),
        gramm: 200,
        amount: 1,
        qty: 3,
      );
      expect(item.subtotal.format(), '1 050');
      expect(item.toJson()['id'], 'p1');
      final restored = CartItem.fromJson(item.toJson());
      expect(restored.id, 'p1');
      expect(restored.qty, 3);
      expect(restored.price.format(), '350');
    });
  });
}
