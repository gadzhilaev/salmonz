import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// Compact app bar: logo+title on root tabs, or back+title on nested screens.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.showLogo = true,
    this.actions,
    this.onBack,
  });

  /// Root tab header: small logo left, title beside it.
  const AppHeader.tab({super.key, required this.title, this.actions})
    : showLogo = true,
      onBack = null;

  /// Nested page: back arrow + title (no logo).
  const AppHeader.nested({
    super.key,
    required this.title,
    this.actions,
    this.onBack,
  }) : showLogo = false;

  final String title;
  final bool showLogo;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  static const double _height = 56;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();
    final showBack = !showLogo && (onBack != null || canPop);

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: _height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              children: [
                if (showBack)
                  IconButton(
                    key: const Key('appHeaderBack'),
                    tooltip: 'Назад',
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                  )
                else if (showLogo)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs),
                    child: Image.asset(
                      'assets/icon/logo_salmonz_small.png',
                      width: 36,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                  ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
