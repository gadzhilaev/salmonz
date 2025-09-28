import 'package:flutter/material.dart';

enum AppTab { home, orders, basket, profile }

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.current,
    required this.onTap,
  });

  final AppTab current;
  final void Function(AppTab tab) onTap;

  static const Color orange = Color(0xFFFF5E1C);
  static const Color inactive = Color(0xFF282828);
  static const double width38 = 30;

  @override
  Widget build(BuildContext context) {
    // контейнер 88 высотой, бордер 1px белый, слева/справа 40, между элементами 38
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Colors.white, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 0),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            label: 'ГЛАВНАЯ',
            active: current == AppTab.home,
            onTap: () => onTap(AppTab.home),
          ),
          const SizedBox(width: width38),
          _NavItem(
            icon: Icons.format_list_bulleted,
            label: 'ЗАКАЗЫ',
            active: current == AppTab.orders,
            onTap: () => onTap(AppTab.orders),
          ),
          const SizedBox(width: width38),
          _NavItem(
            icon: Icons.shopping_cart_outlined,
            label: 'КОРЗИНА',
            active: current == AppTab.basket,
            onTap: () => onTap(AppTab.basket),
          ),
          const SizedBox(width: width38),
          _NavItem(
            icon: Icons.account_circle_outlined,
            label: 'ПРОФИЛЬ',
            active: current == AppTab.profile,
            onTap: () => onTap(AppTab.profile),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  static const Color orange = Color(0xFFFF5E1C);
  static const Color inactive = Color(0xFF282828);

  @override
  Widget build(BuildContext context) {
    final color = active ? orange : inactive;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          // сверху/снизу по 24 — как ты просил
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label, // уже CAPS
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700, // Bold
                  fontSize: 10,
                  height: 17 / 10, // line-height 17px
                  letterSpacing: 0,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}