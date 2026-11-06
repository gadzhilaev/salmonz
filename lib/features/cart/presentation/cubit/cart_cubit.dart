import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/money/money.dart';
import '../../../../widgets/cart.dart';

class CartViewState extends Equatable {
  const CartViewState({
    required this.items,
    required this.total,
    required this.totalQuantity,
  });

  final List<CartItem> items;
  final Money total;
  final int totalQuantity;

  int quantityOf(String productId) {
    for (final item in items) {
      if (item.id == productId) return item.qty;
    }
    return 0;
  }

  @override
  List<Object?> get props => [items, total.asDouble, totalQuantity];
}

/// Thin Cubit over the persistent [Cart] singleton (keeps SharedPreferences).
class CartCubit extends Cubit<CartViewState> {
  CartCubit({Cart? cart})
    : _cart = cart ?? Cart.instance,
      super(_snap(cart ?? Cart.instance)) {
    _cart.addListener(_onChanged);
  }

  final Cart _cart;

  static CartViewState _snap(Cart cart) => CartViewState(
    items: cart.items,
    total: cart.totalSum,
    totalQuantity: cart.totalQuantity,
  );

  void _onChanged() => emit(_snap(_cart));

  Future<void> hydrate() => _cart.load();

  void add(CartItem item) => _cart.add(item);

  void upsert(CartItem item, int qty) => _cart.upsert(item, qty);

  void setQuantity(String id, int qty) => _cart.setQuantity(id, qty);

  void remove(String id) => _cart.remove(id);

  void clear() => _cart.clear();

  @override
  Future<void> close() {
    _cart.removeListener(_onChanged);
    return super.close();
  }
}
