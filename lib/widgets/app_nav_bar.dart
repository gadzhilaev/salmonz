import 'package:flutter/material.dart';

import '../core/responsive/app_breakpoints.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import 'cart.dart';

enum AppTab { home, orders, basket, profile }

/// Bottom navigation. Surface color extends under the home indicator;
/// [SafeArea] is applied once here — tab pages must use `bottom: false`.
class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, required this.current, required this.onTap});

  final AppTab current;
  final void Function(AppTab tab) onTap;

  static const double barHeight = 56;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 600;
    final iconSize = isWide ? AppBreakpoints.iconSize(width) : 22.0;
    final labelSize = isWide ? 11.0 * AppBreakpoints.typeScale(width) : 10.0;
    final contentH = isWide ? 64.0 : barHeight;
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: Cart.instance,
      builder: (context, _) {
        final cartQty = Cart.instance.totalQuantity;
        // Color fills to the physical bottom; padding is inside the paint.
        return Material(
          color: scheme.surface,
          elevation: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(
                top: BorderSide(color: scheme.outline.withValues(alpha: 0.45)),
              ),
            ),
            child: SafeArea(
              top: false,
              minimum: EdgeInsets.zero,
              child: SizedBox(
                height: contentH,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      _NavItem(
                        key: const Key('navHome'),
                        icon: Icons.home_outlined,
                        label: 'Главная',
                        active: current == AppTab.home,
                        iconSize: iconSize,
                        labelSize: labelSize,
                        onTap: () => onTap(AppTab.home),
                      ),
                      _NavItem(
                        key: const Key('navOrders'),
                        icon: Icons.receipt_long_outlined,
                        label: 'Заказы',
                        active: current == AppTab.orders,
                        iconSize: iconSize,
                        labelSize: labelSize,
                        onTap: () => onTap(AppTab.orders),
                      ),
                      _NavItem(
                        key: const Key('navBasket'),
                        icon: Icons.shopping_bag_outlined,
                        label: 'Корзина',
                        active: current == AppTab.basket,
                        iconSize: iconSize,
                        labelSize: labelSize,
                        badge: cartQty > 0 ? cartQty : null,
                        onTap: () => onTap(AppTab.basket),
                      ),
                      _NavItem(
                        key: const Key('navProfile'),
                        icon: Icons.person_outline,
                        label: 'Профиль',
                        active: current == AppTab.profile,
                        iconSize: iconSize,
                        labelSize: labelSize,
                        onTap: () => onTap(AppTab.profile),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool active;
  final double iconSize;
  final double labelSize;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = active ? AppColors.orange : scheme.onSurfaceVariant;
    final badgeText = badge == null ? null : (badge! > 99 ? '99+' : '$badge');

    return Expanded(
      child: InkWell(
        borderRadius: AppRadii.smAll,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: iconSize + 18,
              height: iconSize + 6,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(icon, size: iconSize, color: color),
                  if (badgeText != null)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: const BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.all(Radius.circular(99)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          badgeText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: labelSize,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
