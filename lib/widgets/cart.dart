import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

  final int id;
  final String name;
  final String img;
  final double price;
  final int gramm;
  final int amount;
  int qty;

  double get subtotal => price * qty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'img': img,
    'price': price,
    'gramm': gramm,
    'amount': amount,
    'qty': qty,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'],
    name: json['name'],
    img: json['img'],
    price: (json['price'] as num).toDouble(),
    gramm: json['gramm'],
    amount: json['amount'],
    qty: json['qty'],
  );
}

class Cart extends ChangeNotifier {
  Cart._();
  static final Cart instance = Cart._();

  final Map<int, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList(growable: false);
  double get totalSum => _items.values.fold(0.0, (s, e) => s + e.subtotal);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('cart');
    if (jsonStr != null) {
      final decoded = jsonDecode(jsonStr) as List;
      _items
        ..clear()
        ..addEntries(decoded.map((e) {
          final item = CartItem.fromJson(e);
          return MapEntry(item.id, item);
        }));
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

  void inc(int id) {
    final it = _items[id];
    if (it == null) return;
    it.qty += 1;
    _save();
    notifyListeners();
  }

  void dec(int id) {
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

  void remove(int id) {
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