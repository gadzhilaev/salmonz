import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

enum AppNoticeKind { success, error, warning, info }

/// Branded floating notice — prefer over raw SnackBar.
abstract final class AppNotice {
  static void show(
    BuildContext context, {
    required String message,
    AppNoticeKind kind = AppNoticeKind.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final (Color bg, IconData icon) = switch (kind) {
      AppNoticeKind.success => (AppColors.success, Icons.check_circle_outline),
      AppNoticeKind.error => (AppColors.error, Icons.error_outline),
      AppNoticeKind.warning => (AppColors.warning, Icons.warning_amber_rounded),
      AppNoticeKind.info => (AppColors.info, Icons.info_outline),
    };

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.smAll),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, kind: AppNoticeKind.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, kind: AppNoticeKind.error);

  static void warning(BuildContext context, String message) =>
      show(context, message: message, kind: AppNoticeKind.warning);

  static void info(BuildContext context, String message) =>
      show(context, message: message, kind: AppNoticeKind.info);
}
