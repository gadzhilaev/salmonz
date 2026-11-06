import 'package:flutter/material.dart';
import 'package:salmonz/auth/login.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/network/api_exception.dart';
import 'package:salmonz/core/theme/app_colors.dart';
import 'package:salmonz/core/theme/app_spacing.dart';
import 'package:salmonz/core/theme/theme_controller.dart';
import 'package:salmonz/widgets/app_header.dart';
import 'package:salmonz/widgets/app_notice.dart';
import 'package:url_launcher/url_launcher.dart';

/// Settings: theme, legal (HTTPS), delete account, logout.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Uri _legalUri(String path) {
    final base = AppServices.instance.config.apiBaseUrl.replaceAll(
      RegExp(r'/+$'),
      '',
    );
    // Public legal pages are served by admin-web in local demo, or same host.
    final host = base.contains('127.0.0.1') || base.contains('localhost')
        ? 'http://127.0.0.1:3001'
        : base;
    return Uri.parse('$host$path');
  }

  Future<void> _openLegal(BuildContext context, String path) async {
    final uri = _legalUri(path);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppNotice.error(context, 'Не удалось открыть $uri');
    }
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Сессия будет завершена на этом устройстве.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AppServices.instance.auth.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Login()),
      (_) => false,
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить аккаунт?'),
        content: const Text(
          'Профиль и адреса будут удалены, сессии завершены. '
          'История заказов сохраняется в обезличенном виде.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppServices.instance.profile.deleteAccount();
      await AppServices.instance.auth.logout();
      if (!context.mounted) return;
      AppNotice.success(context, 'Аккаунт удалён');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Login()),
        (_) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      AppNotice.error(context, ApiException.userMessageFrom(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = ThemeScope.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const AppHeader.nested(title: 'Настройки'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return _SettingsTile(
                  key: const Key('themeToggle'),
                  icon: Icons.brightness_6_outlined,
                  title: 'Тема',
                  subtitle: controller.labelRu(),
                  onTap: () => controller.cycle(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Политика конфиденциальности',
              onTap: () => _openLegal(context, '/legal/privacy'),
            ),
            const SizedBox(height: AppSpacing.xs),
            _SettingsTile(
              icon: Icons.description_outlined,
              title: 'Пользовательское соглашение',
              onTap: () => _openLegal(context, '/legal/terms'),
            ),
            const SizedBox(height: AppSpacing.md),
            _SettingsTile(
              icon: Icons.delete_forever_outlined,
              title: 'Удалить аккаунт',
              danger: true,
              onTap: () => _deleteAccount(context),
            ),
            const SizedBox(height: AppSpacing.xs),
            _SettingsTile(
              key: const Key('logoutButton'),
              icon: Icons.logout,
              title: 'Выйти из аккаунта',
              danger: true,
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = danger ? AppColors.error : theme.colorScheme.onSurface;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: AppRadii.mdAll,
      child: InkWell(
        borderRadius: AppRadii.mdAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(color: color),
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
