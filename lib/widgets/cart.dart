import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/money/money.dart';

class CartItem {
  CartItem({
    required this.id,
    required this.name,
    required this.img,
    required this.price,
    required this.gramm,
    required this.amount,
    this.qty = 1,
  });

  final String id;
  final String name;
  final String img;
  final Money price;
  final int gramm;
  final int amount;
  int qty;

  Money get subtotal => price * qty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'img': img,
    'price': price.asDouble,
    'gramm': gramm,
    'amount': amount,
    'qty': qty,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'].toString(),
    name: json['name'] as String,
    img: json['img'] as String,
    price: Money.parse(json['price']),
    gramm: (json['gramm'] as num?)?.toInt() ?? 0,
    amount: (json['amount'] as num?)?.toInt() ?? 1,
    qty: (json['qty'] as num?)?.toInt() ?? 1,
  );
}

class Cart extends ChangeNotifier {
  Cart._();
  static final Cart instance = Cart._();

  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList(growable: false);
  Money get totalSum =>
      _items.values.fold(Money.zero, (s, e) => s + e.subtotal);

  // Convenience for UI that still wants a double.
  double get totalSumDouble => totalSum.asDouble;

  /// Total units across all lines (for nav badge).
  int get totalQuantity => _items.values.fold<int>(0, (s, e) => s + e.qty);

  int quantityOf(String productId) => _items[productId]?.qty ?? 0;

  /// Set absolute quantity; 0 removes the line.
  void setQuantity(String id, int qty) {
    if (qty <= 0) {
      remove(id);
      return;
    }
    final it = _items[id];
    if (it == null) return;
    it.qty = qty;
    _save();
    notifyListeners();
  }

  /// Add [item] if missing, then set quantity.
  void upsert(CartItem item, int qty) {
    if (qty <= 0) {
      remove(item.id);
      return;
    }
    final exist = _items[item.id];
    if (exist == null) {
      _items[item.id] = CartItem(
        id: item.id,
        name: item.name,
        img: item.img,
        price: item.price,
        gramm: item.gramm,
        amount: item.amount,
        qty: qty,
      );
    } else {
      exist.qty = qty;
    }
    _save();
    notifyListeners();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('cart');
    if (jsonStr != null) {
      final decoded = jsonDecode(jsonStr) as List;
      _items
        ..clear()
        ..addEntries(
          decoded.map((e) {
            final item = CartItem.fromJson(Map<String, dynamic>.from(e as Map));
            return MapEntry(item.id, item);
          }),
        );
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _items.values.map((e) => e.toJson()).toList();
    await prefs.setString('cart', jsonEncode(list));
  }

  void add(CartItem item) {
    final exist = _items[item.id];
    if (exist == null) {
      _items[item.id] = item;
    } else {
      exist.qty += item.qty;
    }
    _save();
    notifyListeners();
  }

  void inc(String id) {
    final it = _items[id];
    if (it == null) return;
    it.qty += 1;
    _save();
    notifyListeners();
  }

  void dec(String id) {
    final it = _items[id];
    if (it == null) return;
    if (it.qty > 1) {
      it.qty -= 1;
    } else {
      _items.remove(id);
    }
    _save();
    notifyListeners();
  }

  void remove(String id) {
    _items.remove(id);
    _save();
    notifyListeners();
  }

  Future<void> clear() async {
    _items.clear();
    await _save();
    notifyListeners();
  }
}
