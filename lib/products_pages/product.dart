import 'package:flutter/material.dart';
import '../widgets/cart.dart';

class ProductPage extends StatelessWidget {
  const ProductPage({
    super.key,
    required this.id,
    required this.name,
    required this.img,
    required this.description,
    required this.gramm,
    required this.amount,
    required this.price,
  });

  final int id;
  final String name;
  final String img;
  final String description; // состав
  final int gramm;          // грамм из БД (число)
  final int amount;         // количество из БД (число)
  final double price;

  static const Color bg = Color(0xFFFFFFFF);
  static const Color arrowColor = Color(0xFFCDCDCD);
  static const Color titleDark = Color(0xFF26351E);
  static const Color gray5050 = Color(0xFF505050);
  static const Color gray2828 = Color(0xFF282828);
  static const Color tileBg = Color(0xFFFAFAFA);
  static const Color btnBg = Color(0xFFFF5E1C);

  static const double hLogo = 62;
  static const double ls20 = 0.8; // 4% от 20
  static const double lsBtn = 0.4; // 4% от 10

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- фиксированный appbar ---
              SizedBox(
                height: hLogo + 26,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      left: 20, top: 26,
                      child: SizedBox(
                        width: 24, height: 24,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          splashRadius: 20,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: arrowColor),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      child: Image.asset(
                        'assets/icon/logo_salmonz_small.png',
                        width: 80, height: 62, fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),

              // --- скроллируемый контент ---
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 24),

                    // контейнер с bg image как в products.dart (369x260, радиус 12)
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
                              child: Image.network(
                                img,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Название (uppercase, 20px, w900, lh=130%, letterSpacing 4%)
                    Text(
                      name.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.3, // 130%
                        letterSpacing: ls20,
                        color: titleDark,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // граммы (NN г)
                    Text(
                      '$gramm г.',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        height: 22/18, // ~1.22 (под твои 22px)
                        letterSpacing: 0,
                        color: gray5050,
                      ),
                    ),

                    // количество (NN шт.)
                    Text(
                      '$amount шт.',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        height: 22/18,
                        letterSpacing: 0,
                        color: gray5050,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // "СОСТАВ:"
                    const Text(
                      'СОСТАВ:',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600, // Semi Bold
                        height: 22/16,
                        letterSpacing: 0,
                        color: gray2828,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // описание (если пустое — ничего не рисуем)
                    if (description.trim().isNotEmpty)
                      Text(
                        description,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.5, // 150%
                          letterSpacing: 0,
                          color: gray5050,
                        ),
                      ),

                    const SizedBox(height: 40),

                    // Кнопка "добавить в корзину" + цена справа (как в products.dart)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 173,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () {
                              Cart.instance.add(CartItem(
                                id: id,
                                name: name,
                                img: img,
                                price: price,
                                gramm: gramm,
                                amount: amount,
                                qty: 1,
                              ));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Добавлено в корзину')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: btnBg,
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
                                letterSpacing: lsBtn,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Text(
                          '${_priceFmt(price)} ₽',
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

  static String _priceFmt(double v) {
    final isInt = v == v.roundToDouble();
    return isInt ? v.toInt().toString() : v.toString();
  }
}