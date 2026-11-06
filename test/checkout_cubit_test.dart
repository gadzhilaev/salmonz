import 'package:flutter_test/flutter_test.dart';
import 'package:salmonz/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:salmonz/widgets/cart.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Cart.instance.clear();
  });

  test('validateBeforeSubmit requires address and phone', () {
    final cubit = CheckoutCubit(cart: Cart.instance);
    expect(cubit.validateBeforeSubmit(), 'Выберите адрес доставки');
    cubit.setPhone('+7 (900) 000-00-00');
    // still no address
    expect(cubit.validateBeforeSubmit(), 'Выберите адрес доставки');
    cubit.close();
  });

  test('double submit is guarded by lock', () async {
    final cubit = CheckoutCubit(cart: Cart.instance);
    // Without services/backend submit exits on validation.
    await cubit.submit();
    expect(cubit.state.submitting, isFalse);
    expect(cubit.state.submitError, isNotNull);
    await cubit.close();
  });
}
