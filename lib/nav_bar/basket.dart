import 'package:flutter/material.dart';
import "package:salmonz/widgets/app_nav_bar.dart";
import 'main_screen.dart';
import 'orders.dart';
import 'package:salmonz/nav_bar/profile.dart';
import 'package:salmonz/widgets/cart.dart';
import 'package:salmonz/pages/checkout_page.dart';

class BasketPage extends StatelessWidget {
  const BasketPage({super.key});

  static const bg = Colors.white;
  static const textDark = Color(0xFF26351E);
  static const gray2828 = Color(0xFF282828);
  static const btnOrange = Color(0xFFFF5E1C);
  static const tileBg = Color(0xFFFAFAFA);

  static const double hLogo = 62;
  static const double ls24 = 0.96; // 4% от 24

  @override
  Widget build(BuildContext context) {
    final cart = Cart.instance;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // логотип как в других экранах
              const SizedBox(height: 4),
              Center(
                child: Image.asset(
                  'assets/icon/logo_salmonz_small.png',
                  width: 80, height: 62, fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),

              // КОРЗИНА
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'КОРЗИНА',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    height: 1.0,
                    letterSpacing: ls24,
                    color: textDark,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // контент — слушаем корзину
              Expanded(
                child: AnimatedBuilder(
                  animation: cart,
                  builder: (_, __) {
                    final items = cart.items;
                    if (items.isEmpty) {
                      return const Center(child: Text('Корзина пока пустая'));
                    }
                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, i) {
                        final it = items[i];
                        return _BasketTile(item: it);
                      },
                    );
                  },
                ),
              ),

              // итого + кнопка
              AnimatedBuilder(
                animation: cart,
                builder: (_, __) {
                  return Column(
                    children: [
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'ИТОГО:',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                              height: 1.0,
                              letterSpacing: ls24,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_priceFmt(cart.totalSum)} ₽',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              fontSize: 24,
                              height: 1.0,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: cart.items.isEmpty ? null : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CheckoutPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: btnOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),
                          child: const Text(
                            'ОФОРМИТЬ ЗАКАЗ',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              height: 1.0,
                              letterSpacing: 0.48, // 4%
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),

      // нижний навбар
      bottomNavigationBar: AppNavBar(
        current: AppTab.basket,
        onTap: (tab) {
          switch (tab) {
            case AppTab.home:
              Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const SuccessPage()),
              );
              break;
            case AppTab.orders:
              Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const OrdersPage()),
              );
              break;
            case AppTab.basket:
              break;
            case AppTab.profile:
              Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
              break;
          }
        },
      ),
    );
  }

  static String _priceFmt(double v) {
    final isInt = v == v.roundToDouble();
    return isInt ? v.toInt().toString() : v.toStringAsFixed(2).replaceAll(RegExp(r'\.0+$'), '');
  }
}

class _BasketTile extends StatelessWidget {
  const _BasketTile({required this.item});
  final CartItem item;

  static const textDark = Color(0xFF26351E);
  static const gray2828 = Color(0xFF282828);
  static const tileBg = Color(0xFFFAFAFA);
  static const orange = Color(0xFFFF5E1C);

  @override
  Widget build(BuildContext context) {
    final cart = Cart.instance;

    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // картинка 120 x 80, r=8, background-image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 120,
                height: 80,
                color: tileBg,
                child: Image.network(item.img, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // правый блок
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // название (верх карточки)
                  Text(
                    item.name.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      height: 1.3, // 130%
                      letterSpacing: 0.56, // 4% от 14
                      color: textDark,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // "NN шт." + цена (за 1 * qty) справа с отступом 16
                  Row(
                    children: [
                      Text(
                        '${item.amount} шт',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          height: 22 / 14,
                          color: gray2828,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${_priceFmt(item.subtotal)} ₽',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          height: 1.0,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // − qty +
                  Row(
                    children: [
                      _SquareBtn(
                        icon: Icons.arrow_back_ios_new,
                        onTap: () => cart.dec(item.id),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${item.qty}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          height: 1.0,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 16),
                      _SquareBtn(
                        // та же кнопка, но «вправо»
                        icon: Icons.arrow_forward_ios,
                        onTap: () => cart.inc(item.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // крестик удалить — справа по центру высоты блока (80), отцентрируем
        Positioned(
          right: 0,
          top: 80/2 - 12, // иконка 24 -> по центру
          child: InkWell(
            onTap: () => cart.remove(item.id),
            borderRadius: BorderRadius.circular(12),
            child: const SizedBox(
              width: 24, height: 24,
              child: Icon(Icons.close, color: orange, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  static String _priceFmt(double v) {
    final isInt = v == v.roundToDouble();
    return isInt ? v.toInt().toString() : v.toStringAsFixed(2).replaceAll(RegExp(r'\.0+$'), '');
  }
}

class _SquareBtn extends StatelessWidget {
  const _SquareBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(2),
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(2),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 12, color: const Color(0xFFFF5E1C)),
      ),
    );
  }
}