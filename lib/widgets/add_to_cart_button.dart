import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Full-width orange CTA that switches between "В корзину" and − N +.
///
/// Both modes share the same size, radius and brand color.
class AddToCartButton extends StatelessWidget {
  const AddToCartButton({
    super.key,
    required this.quantity,
    required this.onAdd,
    required this.onChanged,
    this.enabled = true,
    this.height = 40,
    this.label = 'В корзину',
    this.max = 99,
  });

  final int quantity;
  final VoidCallback onAdd;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final double height;
  final String label;
  final int max;

  @override
  Widget build(BuildContext context) {
    final showQty = quantity > 0;
    final bg = enabled
        ? AppColors.orange
        : AppColors.orange.withValues(alpha: 0.38);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: bg,
        borderRadius: AppRadii.pillAll,
        clipBehavior: Clip.antiAlias,
        child: showQty
            ? _QtyBar(
                quantity: quantity,
                height: height,
                max: max,
                enabled: enabled,
                onChanged: onChanged,
              )
            : InkWell(
                key: const Key('addToCart'),
                onTap: enabled ? onAdd : null,
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _QtyBar extends StatelessWidget {
  const _QtyBar({
    required this.quantity,
    required this.height,
    required this.max,
    required this.enabled,
    required this.onChanged,
  });

  final int quantity;
  final double height;
  final int max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SideHit(
          key: const Key('qtyDec'),
          icon: Icons.remove,
          enabled: enabled && quantity > 0,
          onTap: () => onChanged(quantity - 1),
        ),
        Expanded(
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              height: 1.1,
            ),
          ),
        ),
        _SideHit(
          key: const Key('qtyInc'),
          icon: Icons.add,
          enabled: enabled && quantity < max,
          onTap: () => onChanged(quantity + 1),
        ),
      ],
    );
  }
}

class _SideHit extends StatelessWidget {
  const _SideHit({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Center(
          child: Icon(
            icon,
            size: 20,
            color: Colors.white.withValues(alpha: enabled ? 1 : 0.45),
          ),
        ),
      ),
    );
  }
}
