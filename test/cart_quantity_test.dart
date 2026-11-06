import 'package:flutter_test/flutter_test.dart';
import 'package:salmonz/core/money/money.dart';
import 'package:salmonz/widgets/cart.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Cart.instance.clear();
  });

  CartItem item() => CartItem(
    id: 'p1',
    name: 'Филадельфия',
    img: '',
    price: Money.fromRubles(499),
    gramm: 250,
    amount: 1,
  );

  test('upsert and quantityOf sync', () {
    expect(Cart.instance.quantityOf('p1'), 0);
    Cart.instance.upsert(item(), 2);
    expect(Cart.instance.quantityOf('p1'), 2);
    expect(Cart.instance.totalQuantity, 2);
    Cart.instance.upsert(item(), 0);
    expect(Cart.instance.quantityOf('p1'), 0);
    expect(Cart.instance.items, isEmpty);
  });

  test('inc/dec update totals', () {
    Cart.instance.add(item());
    Cart.instance.inc('p1');
    expect(Cart.instance.quantityOf('p1'), 2);
    expect(Cart.instance.totalSum.asDouble, closeTo(998, 0.01));
    Cart.instance.dec('p1');
    Cart.instance.dec('p1');
    expect(Cart.instance.quantityOf('p1'), 0);
  });
}
