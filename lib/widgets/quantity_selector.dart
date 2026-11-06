import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Quantity control. Prefer [AddToCartButton] in product grids.
///
/// [filled] uses brand orange bar matching cart CTA style.
class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.dense = false,
    this.filled = false,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final bool dense;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      final h = dense ? 36.0 : 40.0;
      return SizedBox(
        height: h,
        child: Material(
          color: AppColors.orange,
          borderRadius: AppRadii.pillAll,
          clipBehavior: Clip.antiAlias,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Hit(
                key: const Key('qtyDec'),
                icon: Icons.remove,
                onTap: quantity > min ? () => onChanged(quantity - 1) : null,
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 28),
                child: Text(
                  '$quantity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              _Hit(
                key: const Key('qtyInc'),
                icon: Icons.add,
                onTap: quantity < max ? () => onChanged(quantity + 1) : null,
              ),
            ],
          ),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final size = dense ? 32.0 : 36.0;

    Widget roundButton({
      required IconData icon,
      required VoidCallback? onTap,
      Key? key,
    }) {
      return Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppRadii.smAll,
        child: InkWell(
          key: key,
          onTap: onTap,
          borderRadius: AppRadii.smAll,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: dense ? 16 : 18),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        roundButton(
          key: const Key('qtyDec'),
          icon: Icons.remove,
          onTap: quantity > min ? () => onChanged(quantity - 1) : null,
        ),
        SizedBox(
          width: dense ? 28 : 36,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        roundButton(
          key: const Key('qtyInc'),
          icon: Icons.add,
          onTap: quantity < max ? () => onChanged(quantity + 1) : null,
        ),
      ],
    );
  }
}

class _Hit extends StatelessWidget {
  const _Hit({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: double.infinity,
        child: Icon(
          icon,
          size: 18,
          color: Colors.white.withValues(alpha: onTap == null ? 0.45 : 1),
        ),
      ),
    );
  }
}
