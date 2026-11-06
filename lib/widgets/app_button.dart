import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

/// Design-system button. Loading keeps brand color and fixed height;
/// disabled is visually distinct from loading.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.expanded = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final bool expanded;
  final IconData? icon;

  static const double height = 48;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canTap = onPressed != null && !loading;

    final progressColor = switch (variant) {
      AppButtonVariant.primary => Colors.white,
      AppButtonVariant.danger => scheme.onError,
      AppButtonVariant.secondary || AppButtonVariant.ghost => AppColors.orange,
    };

    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: progressColor,
              ),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );

    final semantics = Semantics(
      button: true,
      enabled: canTap,
      label: loading ? '$label, загрузка' : label,
      child: child,
    );

    final ButtonStyle? primaryStyle = variant == AppButtonVariant.primary
        ? FilledButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.white,
            disabledBackgroundColor: loading
                ? AppColors.orange
                : AppColors.orange.withValues(alpha: 0.38),
            disabledForegroundColor: Colors.white.withValues(
              alpha: loading ? 1 : 0.7,
            ),
            minimumSize: const Size(0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          )
        : null;

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: canTap ? onPressed : null,
        style: primaryStyle,
        child: semantics,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: canTap ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.orange,
          disabledForegroundColor: loading
              ? AppColors.orange
              : scheme.onSurface.withValues(alpha: 0.38),
          side: BorderSide(
            color: canTap || loading
                ? AppColors.orange
                : scheme.outline.withValues(alpha: 0.4),
          ),
          minimumSize: const Size(0, height),
        ),
        child: semantics,
      ),
      AppButtonVariant.ghost => TextButton(
        onPressed: canTap ? onPressed : null,
        style: TextButton.styleFrom(minimumSize: const Size(0, height)),
        child: semantics,
      ),
      AppButtonVariant.danger => FilledButton(
        onPressed: canTap ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: scheme.error,
          foregroundColor: scheme.onError,
          disabledBackgroundColor: loading
              ? scheme.error
              : scheme.error.withValues(alpha: 0.38),
          disabledForegroundColor: scheme.onError,
          minimumSize: const Size(0, height),
        ),
        child: semantics,
      ),
    };

    if (!expanded) return button;
    return SizedBox(width: double.infinity, height: height, child: button);
  }
}
