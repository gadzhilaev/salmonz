import 'package:flutter/material.dart';

import '../core/responsive/app_breakpoints.dart';

enum AppTab { home, orders, basket, profile }

class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, required this.current, required this.onTap});

  final AppTab current;
  final void Function(AppTab tab) onTap;

  static const Color orange = Color(0xFFFF5E1C);
  static const Color inactive = Color(0xFF282828);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 600;
    final iconSize = isWide ? AppBreakpoints.iconSize(width) : 20.0;
    final labelSize = isWide ? 11.0 * AppBreakpoints.typeScale(width) : 10.0;
    final horizontalPad = width < 360 ? 12.0 : (width < 600 ? 24.0 : 40.0);
    final gap = width < 360 ? 8.0 : (width < 600 ? 16.0 : 24.0);
    final barHeight = isWide ? 80.0 : 72.0;

    return SafeArea(
      top: false,
      child: Container(
        height: barHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: horizontalPad),
        child: Row(
          children: [
            _NavItem(
              key: const Key('navHome'),
              icon: Icons.home_outlined,
              label: 'ГЛАВНАЯ',
              active: current == AppTab.home,
              iconSize: iconSize,
              labelSize: labelSize,
              onTap: () => onTap(AppTab.home),
            ),
            SizedBox(width: gap),
            _NavItem(
              key: const Key('navOrders'),
              icon: Icons.format_list_bulleted,
              label: 'ЗАКАЗЫ',
              active: current == AppTab.orders,
              iconSize: iconSize,
              labelSize: labelSize,
              onTap: () => onTap(AppTab.orders),
            ),
            SizedBox(width: gap),
            _NavItem(
              key: const Key('navBasket'),
              icon: Icons.shopping_cart_outlined,
              label: 'КОРЗИНА',
              active: current == AppTab.basket,
              iconSize: iconSize,
              labelSize: labelSize,
              onTap: () => onTap(AppTab.basket),
            ),
            SizedBox(width: gap),
            _NavItem(
              key: const Key('navProfile'),
              icon: Icons.account_circle_outlined,
              label: 'ПРОФИЛЬ',
              active: current == AppTab.profile,
              iconSize: iconSize,
              labelSize: labelSize,
              onTap: () => onTap(AppTab.profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.iconSize,
    required this.labelSize,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final double iconSize;
  final double labelSize;
  final VoidCallback onTap;

  static const Color orange = Color(0xFFFF5E1C);
  static const Color inactive = Color(0xFF282828);

  @override
  Widget build(BuildContext context) {
    final color = active
        ? orange
        : (Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.onSurface
              : inactive);

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: iconSize),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: labelSize,
                    height: 17 / 10,
                    letterSpacing: 0,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
