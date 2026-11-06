import 'package:flutter_test/flutter_test.dart';
import 'package:salmonz/core/money/money.dart';
import 'package:salmonz/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salmonz/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:salmonz/widgets/cart.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('AuthCubit starts as AuthInitial', () {
    final cubit = AuthCubit();
    expect(cubit.state, isA<AuthInitial>());
    cubit.close();
  });

  test('CartCubit mirrors Cart quantity changes', () async {
    final cart = Cart.instance;
    cart.clear();
    final cubit = CartCubit(cart: cart);
    expect(cubit.state.totalQuantity, 0);

    cart.add(
      CartItem(
        id: 'p1',
        name: 'Roll',
        img: '',
        price: Money.fromRubles(100),
        gramm: 200,
        amount: 1,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.totalQuantity, greaterThan(0));
    cart.clear();
    await cubit.close();
  });
}
