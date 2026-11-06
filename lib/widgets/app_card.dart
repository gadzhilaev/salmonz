import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Padding(padding: padding, child: child);
    final card = Material(
      color: color ?? scheme.surface,
      borderRadius: AppRadii.mdAll,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, borderRadius: AppRadii.mdAll, child: content),
    );
    if (margin == null) return card;
    return Padding(padding: margin!, child: card);
  }
}
