import 'package:flutter/material.dart';
import 'package:salmonz/data/models/models.dart';

/// Lightweight admin product detail (optional view).
class ProductAdminViewPage extends StatelessWidget {
  const ProductAdminViewPage({super.key, required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if ((product.imageUrl ?? '').isNotEmpty)
            Image.network(product.imageUrl!, height: 200, fit: BoxFit.cover),
          const SizedBox(height: 12),
          Text(
            product.price.formatRub(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(product.description),
          Text(product.isAvailable ? 'В наличии' : 'Нет в наличии'),
        ],
      ),
    );
  }
}
