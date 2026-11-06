import 'package:flutter/material.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import 'package:salmonz/core/theme/app_spacing.dart';
import 'package:salmonz/profile/addresses_page.dart';
import 'package:salmonz/profile/edit_profile_page.dart';
import 'package:salmonz/profile/settings_page.dart';
import 'package:salmonz/profile/support_page.dart';
import 'package:salmonz/widgets/app_header.dart';
import 'package:salmonz/widgets/app_network_image.dart';
import 'package:salmonz/widgets/async_body.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<_UserVm> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadMe();
  }

  Future<_UserVm> _loadMe() async {
    final user = await AppServices.instance.profile.getMe();
    return _UserVm(
      email: user.email,
      name: user.name,
      img: user.avatarUrl ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const AppHeader.tab(title: 'Профиль'),
      body: SafeArea(
        top: false,
        bottom: false,
        child: AppPageContainer(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _loadMe());
              try {
                await _future;
              } catch (_) {}
            },
            child: FutureBuilder<_UserVm>(
              future: _future,
              builder: (context, snap) {
                return AsyncBody<_UserVm>(
                  snapshot: snap,
                  scrollable: true,
                  onRetry: () async {
                    setState(() => _future = _loadMe());
                    try {
                      await _future;
                    } catch (_) {}
                  },
                  builder: (me) => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      Material(
                        color: theme.colorScheme.surface,
                        borderRadius: AppRadii.mdAll,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              ClipOval(
                                child: SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: me.img.isNotEmpty
                                      ? AppNetworkImage(
                                          url: me.img,
                                          kind: AppImageKind.avatar,
                                          width: 72,
                                          height: 72,
                                          memCacheWidth: 160,
                                        )
                                      : ColoredBox(
                                          color: theme
                                              .colorScheme
                                              .surfaceContainerHighest,
                                          child: Icon(
                                            Icons.person,
                                            size: 36,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      me.name.isNotEmpty
                                          ? me.name
                                          : 'Без имени',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      me.email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ProfileRow(
                        key: const Key('editProfileEntry'),
                        icon: Icons.edit_outlined,
                        title: 'Редактировать профиль',
                        onTap: () async {
                          final updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfilePage(),
                            ),
                          );
                          if (updated == true && mounted) {
                            setState(() => _future = _loadMe());
                          }
                        },
                      ),
                      _ProfileRow(
                        icon: Icons.home_outlined,
                        title: 'Мои адреса',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddressesPage(),
                            ),
                          );
                        },
                      ),
                      _ProfileRow(
                        key: const Key('supportEntry'),
                        icon: Icons.support_agent_outlined,
                        title: 'Поддержка',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SupportPage(),
                            ),
                          );
                        },
                      ),
                      _ProfileRow(
                        key: const Key('settingsEntry'),
                        icon: Icons.settings_outlined,
                        title: 'Настройки',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: AppRadii.mdAll,
        child: InkWell(
          borderRadius: AppRadii.mdAll,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            child: Row(
              children: [
                Icon(icon, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserVm {
  const _UserVm({required this.email, required this.name, required this.img});

  final String email;
  final String name;
  final String img;
}
