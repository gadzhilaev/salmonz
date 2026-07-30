import 'package:flutter/material.dart';
import 'package:salmonz/data/models/models.dart';
import '../widgets/cart.dart';

class ProductPage extends StatelessWidget {
  const ProductPage({super.key, required this.product});

  final ProductModel product;

  static const Color bg = Color(0xFFFFFFFF);
  static const Color arrowColor = Color(0xFFCDCDCD);
  static const Color titleDark = Color(0xFF26351E);
  static const Color gray5050 = Color(0xFF505050);
  static const Color gray2828 = Color(0xFF282828);
  static const Color tileBg = Color(0xFFFAFAFA);
  static const Color btnBg = Color(0xFFFF5E1C);

  static const double hLogo = 62;
  static const double ls20 = 0.8;
  static const double lsBtn = 0.4;

  @override
  Widget build(BuildContext context) {
    final img = product.imageUrl ?? '';
    final gramm = product.weight ?? 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: arrowColor,
                          ),
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
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 24),
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
                              child: img.isEmpty
                                  ? const Center(
                                      child: Icon(
                                        Icons.restaurant_menu_outlined,
                                      ),
                                    )
                                  : Image.network(
                                      img,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Center(
                                            child: Icon(
                                              Icons.restaurant_menu_outlined,
                                            ),
                                          ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      product.name.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.3,
                        letterSpacing: ls20,
                        color: titleDark,
                      ),
                    ),
                    if (gramm > 0) ...[
                      const SizedBox(height: 12),
                      Text(
                        '$gramm г.',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          height: 22 / 18,
                          color: gray5050,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Text(
                      'СОСТАВ:',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 22 / 16,
                        color: gray2828,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (product.description.trim().isNotEmpty)
                      Text(
                        product.description,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          color: gray5050,
                        ),
                      ),
                    const SizedBox(height: 40),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 173,
                          height: 46,
                          child: ElevatedButton(
                            key: const Key('addToCart'),
                            onPressed: () {
                              Cart.instance.add(
                                CartItem(
                                  id: product.id,
                                  name: product.name,
                                  img: img,
                                  price: product.price,
                                  gramm: gramm,
                                  amount: 1,
                                  qty: 1,
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Добавлено в корзину'),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: btnBg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            child: const Text(
                              'ДОБАВИТЬ В КОРЗИНУ',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                                height: 1.0,
                                letterSpacing: lsBtn,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Text(
                          product.price.formatRub(),
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
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
