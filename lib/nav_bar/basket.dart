import 'package:flutter/material.dart';
import 'package:salmonz/core/responsive/app_breakpoints.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import 'package:salmonz/pages/checkout_page.dart';
import 'package:salmonz/widgets/cart.dart';

class BasketPage extends StatelessWidget {
  const BasketPage({super.key, this.embedded = false});

  final bool embedded;

  static const textDark = Color(0xFF26351E);
  static const gray2828 = Color(0xFF282828);
  static const btnOrange = Color(0xFFFF5E1C);
  static const tileBg = Color(0xFFFAFAFA);

  static const double hLogo = 62;
  static const double ls24 = 0.96;

  @override
  Widget build(BuildContext context) {
    final cart = Cart.instance;
    final width = MediaQuery.sizeOf(context).width;
    final scale = AppBreakpoints.typeScale(width);
    final controlH = AppBreakpoints.controlHeight(width);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: AppPageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 4),
              Center(
                child: Image.asset(
                  'assets/icon/logo_salmonz_small.png',
                  width: 80,
                  height: 62,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'КОРЗИНА',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w900,
                    fontSize: 24 * scale,
                    height: 1.0,
                    letterSpacing: ls24,
                    color: textDark,
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
                        return _BasketTile(item: it, scale: scale);
                      },
                    );
                  },
                ),
              ),
              AnimatedBuilder(
                animation: cart,
                builder: (_, __) {
                  return Column(
                    children: [
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ИТОГО:',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 24 * scale,
                              height: 1.0,
                              letterSpacing: ls24,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cart.totalSum.formatRub(),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              fontSize: 24 * scale,
                              height: 1.0,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: controlH,
                        child: ElevatedButton(
                          key: const Key('cartCheckoutButton'),
                          onPressed: cart.items.isEmpty
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CheckoutPage(),
                                    ),
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
                              letterSpacing: 0.48,
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
    );
  }
}

class _BasketTile extends StatelessWidget {
  const _BasketTile({required this.item, required this.scale});
  final CartItem item;
  final double scale;

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
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 120,
                height: 80,
                color: tileBg,
                child: Image.network(
                  item.img,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.restaurant_menu_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                      fontSize: 14 * scale,
                      height: 1.3,
                      letterSpacing: 0.56,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${item.amount} шт',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          fontSize: 14 * scale,
                          height: 22 / 14,
                          color: gray2828,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        item.subtotal.formatRub(),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 16 * scale,
                          height: 1.0,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _SquareBtn(
                        icon: Icons.arrow_back_ios_new,
                        onTap: () => cart.dec(item.id),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${item.qty}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          fontSize: 16 * scale,
                          height: 1.0,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 16),
                      _SquareBtn(
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
        Positioned(
          right: 0,
          top: 80 / 2 - 12,
          child: InkWell(
            onTap: () => cart.remove(item.id),
            borderRadius: BorderRadius.circular(12),
            child: const SizedBox(
              width: 24,
              height: 24,
              child: Icon(Icons.close, color: orange, size: 20),
            ),
          ),
        ),
      ],
    );
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
        width: 32,
        height: 32,
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
