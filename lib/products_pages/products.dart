import 'package:flutter/material.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/money/money.dart';
import 'package:salmonz/data/models/models.dart';

import 'product.dart';
import '../widgets/cart.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({
    super.key,
    required this.title,
    required this.categoryId,
  });
  final String title;
  final String categoryId;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late Future<List<ProductModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadProducts();
  }

  Future<List<ProductModel>> _loadProducts() async {
    final page = await AppServices.instance.catalog.getProducts(
      categoryId: widget.categoryId,
      limit: 100,
    );
    return page.data;
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFFFFFF);
    const arrowColor = Color(0xFFCDCDCD);
    const titleColor = Color(0xFF26351E);

    const double hLogo = 62;
    const double ls24 = 0.96;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: hLogo + 26,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      left: 20,
                      top: 26,
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          splashRadius: 20,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new,
                              size: 20, color: arrowColor),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      child: Image.asset(
                        'assets/icon/logo_salmonz_small.png',
                        width: 80,
                        height: 62,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<ProductModel>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Ошибка: ${snap.error}'));
                    }
                    final items = snap.data ?? [];
                    if (items.isEmpty) {
                      return const Center(child: Text('Ничего не найдено'));
                    }

                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: items.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              Text(
                                widget.title.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                  letterSpacing: ls24,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          );
                        }

                        final p = items[index - 1];
                        return Column(
                          children: [
                            _ProductCard(
                              product: p,
                              onTap: p.isAvailable
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductPage(
                                            product: p,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                            ),
                            const SizedBox(height: 26),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    this.onTap,
  });

  final ProductModel product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const tileBg = Color(0xFFFAFAFA);
    const nameColor = Color(0xFF26351E);
    const descColor = Color(0xFF282828);
    const btnBg = Color(0xFFFF5E1C);
    const double ls18 = 0.72;
    final inStock = product.isAvailable;
    final imageUrl = product.imageUrl ?? '';
    final price = product.price;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 260,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: tileBg),
                  Positioned.fill(
                    child: Opacity(
                      opacity: inStock ? 1.0 : 0.3,
                      child: imageUrl.isEmpty
                          ? const Center(child: Icon(Icons.restaurant_menu_outlined))
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Center(child: Icon(Icons.restaurant_menu_outlined)),
                            ),
                    ),
                  ),
                  if (!inStock)
                    const Center(
                      child: Text(
                        'НЕТ В НАЛИЧИИ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          height: 21 / 14,
                          letterSpacing: 0,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Opacity(
            opacity: inStock ? 1.0 : 0.3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: ls18,
                    color: nameColor,
                  ),
                ),
                if (product.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    product.description,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      letterSpacing: 0,
                      color: descColor,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 173,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: inStock
                            ? () {
                                Cart.instance.add(CartItem(
                                  id: product.id,
                                  name: product.name,
                                  img: imageUrl,
                                  price: price,
                                  gramm: product.weight ?? 0,
                                  amount: 1,
                                  qty: 1,
                                ));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Добавлено в корзину')),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: btnBg,
                          disabledBackgroundColor:
                              const Color(0xFFFF5E1C).withValues(alpha: 0.4),
                          disabledForegroundColor:
                              Colors.white.withValues(alpha: 0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text(
                          'ДОБАВИТЬ В КОРЗИНУ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            height: 1.0,
                            letterSpacing: 0.4,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Text(
                      price.formatRub(),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                        height: 1.0,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kept for any leftover imports; prefer [ProductModel].
typedef Product = ProductModel;

/// Re-export money for convenience in product screens.
typedef ProductMoney = Money;
