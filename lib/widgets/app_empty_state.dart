import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import 'app_button.dart';

/// Centered empty state for the area between AppBar and bottom nav.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  /// Short headline. Falls back to [message] when null.
  final String? title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = title ?? message;
    final showSubtitle = title != null && message.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 360,
              // Stay within the visible pane (not full screen under bars).
              maxHeight: constraints.hasBoundedHeight
                  ? constraints.maxHeight
                  : double.infinity,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 52,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    headline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (showSubtitle) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: actionLabel!,
                      onPressed: onAction,
                      expanded: false,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
