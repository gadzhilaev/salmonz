import 'package:flutter_test/flutter_test.dart';
import 'package:salmonz/data/models/models.dart';

void main() {
  test('OrderQuoteModel parses money strings and availability', () {
    final quote = OrderQuoteModel.fromJson({
      'items': [
        {
          'productId': 'p1',
          'productName': 'Roll A',
          'unitPrice': '429.00',
          'quantity': 2,
          'lineTotal': '858.00',
          'isAvailable': true,
        },
        {
          'productId': 'p2',
          'productName': 'Sold out',
          'unitPrice': '900.00',
          'quantity': 1,
          'lineTotal': '900.00',
          'isAvailable': false,
        },
      ],
      'subtotal': '858.00',
      'deliveryFee': '249.00',
      'total': '1107.00',
      'currency': 'RUB',
      'freeDeliveryThreshold': 1500,
      'deliveryFeeAmount': 249,
    });

    expect(quote.items.length, 2);
    expect(quote.items.first.unitPrice.format(), '429');
    expect(quote.items.first.lineTotal.formatRub(), '858 ₽');
    expect(quote.subtotal.format(), '858');
    expect(quote.deliveryFee.format(), '249');
    expect(quote.total.formatRub(), '1 107 ₽');
    expect(quote.currency, 'RUB');
    expect(quote.freeDeliveryThreshold, 1500);
    expect(quote.deliveryFeeAmount, 249);
    expect(quote.unavailableItems.single.productId, 'p2');
  });
}
