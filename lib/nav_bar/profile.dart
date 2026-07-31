import 'package:flutter/material.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/responsive/app_breakpoints.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import 'package:salmonz/core/theme/theme_controller.dart';
import '../profile/legal/legal_text_page.dart';
import '../profile/legal/legal_texts.dart';
import '../profile/edit_profile_page.dart';
import '../profile/addresses_page.dart';
import '../auth/login.dart';
import '../profile/support_page.dart';
import '../admin/admin_panel_page.dart';
import '../widgets/async_body.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<_UserVm> _future;
  final _nameKey = GlobalKey(); // ключ для текста имени
  double? _nameBottomDy;
  static const titleDark = Color(0xFF26351E);
  static const orange = Color(0xFFFF5E1C);
  static const grayText = Color(0xFF000000);
  static const secondary = Color(0xFF282828);

  static const double ls24 = 0.96; // 4% от 24

  @override
  void initState() {
    super.initState();
    _future = _loadMe();
  }

  void _captureNameBottom() {
    final box = _nameKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final top = box.localToGlobal(Offset.zero).dy;
      final bottom = top + box.size.height; // 👈 низ виджета имени
      setState(() => _nameBottomDy = bottom);
    }
  }

  Future<_UserVm> _loadMe() async {
    final user = await AppServices.instance.profile.getMe();
    return _UserVm(
      email: user.email,
      name: user.name,
      img: user.avatarUrl ?? '',
      isAdmin: user.isAdmin,
      lang: 'ru',
    );
  }

  void _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LogoutConfirmDialog(),
    );
    if (ok == true) {
      await AppServices.instance.auth.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Login()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = AppBreakpoints.typeScale(MediaQuery.sizeOf(context).width);
    final tileH = AppBreakpoints.controlHeight(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: AppPageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 4),
              Center(
                child: Image.asset(
                  'assets/icon/logo_salmonz_small.png',
                  width: 80,
                  height: 62,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ПРОФИЛЬ',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w900,
                        fontSize: 24 * scale,
                        height: 1.0,
                        letterSpacing: ls24,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.onSurface
                            : titleDark,
                      ),
                    ),
                  ),
                  Semantics(
                    identifier: 'logoutButton',
                    button: true,
                    label: 'Выйти',
                    child: IconButton(
                      key: const Key('logoutButton'),
                      onPressed: _logout,
                      icon: const Icon(
                        Icons.logout_outlined,
                        size: 24,
                        color: orange,
                      ),
                      tooltip: 'Выйти',
                    ),
                  ),
                ],
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _future = _loadMe();
                    });
                    try {
                      await _future;
                    } catch (_) {}
                  },
                  child: FutureBuilder<_UserVm>(
                    future: _future,
                    builder: (context, snap) {
                      return AsyncBody<_UserVm>(
                        snapshot: snap,
                        onRetry: () async {
                          setState(() {
                            _future = _loadMe();
                          });
                          try {
                            await _future;
                          } catch (_) {}
                        },
                        scrollable: true,
                        builder: (me) => ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            const SizedBox(height: 8),
                            // Аватар + имя/почта
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // круг 120x120 с кнопкой смены
                                Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    ClipOval(
                                      child: InkWell(
                                        child: Container(
                                          width: 120,
                                          height: 120,
                                          color: const Color(0xFFEFEFEF),
                                          child: (me.img.isNotEmpty)
                                              ? Image.network(
                                                  me.img,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Icon(
                                                        Icons.person,
                                                        size: 56,
                                                        color: secondary,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons.person,
                                                  size: 56,
                                                  color: secondary,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (me.name.isNotEmpty
                                                ? me.name
                                                : 'Без имени')
                                            .toUpperCase(),
                                        key: _nameKey,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                          height: 23 / 18,
                                          color: secondary,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        me.email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                          height: 1.0,
                                          color: grayText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            _ThemeModeTile(
                              key: const Key('themeToggle'),
                              height: tileH,
                            ),
                            const SizedBox(height: 8),
                            _ProfileTile(
                              key: const Key('editProfileEntry'),
                              semanticsId: 'editProfileEntry',
                              icon: Icons.account_circle_outlined,
                              text: 'Редактировать профиль',
                              height: tileH,
                              onTap: () async {
                                final updated = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const EditProfilePage(),
                                  ),
                                );
                                if (updated == true && mounted) {
                                  setState(() {
                                    _future =
                                        _loadMe(); // <-- заново грузим данные
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            _ProfileTile(
                              icon: Icons.home_outlined,
                              text: 'Мои адреса',
                              height: tileH,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AddressesPage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            _ProfileTile(
                              icon: Icons.translate_rounded,
                              text: 'Изменить язык',
                              height: tileH,
                              onTap: _openLanguageSheet,
                            ),
                            const SizedBox(height: 8),
                            _ProfileTile(
                              icon: Icons.description_outlined,
                              text: 'Политика конфиденциальности',
                              height: tileH,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LegalTextPage(
                                      caption: privacyCaption,
                                      body: privacyBody,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            _ProfileTile(
                              icon: Icons.description_outlined,
                              text: 'Пользовательское соглашение',
                              height: tileH,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LegalTextPage(
                                      caption: termsCaption,
                                      body: termsBody,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            _ProfileTile(
                              key: const Key('supportEntry'),
                              semanticsId: 'supportEntry',
                              icon: Icons.contact_support_outlined,
                              text: 'Написать в поддержку',
                              height: tileH,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SupportPage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            if (me.isAdmin)
                              _ProfileTile(
                                key: const Key('adminPanelEntry'),
                                semanticsId: 'adminPanelEntry',
                                icon: Icons.person_pin_circle_outlined,
                                text: 'Админ панель',
                                height: tileH,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AdminPanelPage(),
                                    ),
                                  );
                                },
                              ),
                            if (me.isAdmin) const SizedBox(height: 8),

                            const SizedBox(height: 16),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLanguageSheet() async {
    final me = await _future;

    if (!mounted) return;

    // зафиксируем актуальное положение имени на экране прямо сейчас
    _captureNameBottom();

    final mq = MediaQuery.of(context);
    // fallback если не удалось измерить (как раньше: до логотипа/заголовка)
    const double topGapFixed = 4 + 62 + 24;
    final double fallbackTop = mq.padding.top + topGapFixed;

    // верхняя кромка — это верх текста ИМЕНИ
    final double anchorTop = _nameBottomDy ?? fallbackTop;

    // высота шторки = высота экрана - положение якоря (имя)
    final double sheetHeight = (mq.size.height - anchorTop).clamp(
      300.0,
      mq.size.height,
    );

    if (!mounted) return;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _LanguageSheet(initialLang: me.lang, desiredHeight: sheetHeight),
    );

    if (chosen != null && chosen != me.lang) {
      // Language preference is client-only (API has no lang field yet).
      if (!mounted) return;
      setState(() {
        _future = Future.value(
          _UserVm(
            email: me.email,
            name: me.name,
            img: me.img,
            isAdmin: me.isAdmin,
            lang: chosen,
          ),
        );
      });
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => _captureNameBottom());
    }
  }
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({super.key, this.height = 48});

  static const orange = Color(0xFFFF5E1C);
  final double height;

  @override
  Widget build(BuildContext context) {
    final controller = ThemeScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => controller.cycle(),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: orange, width: 1),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Icon(
                  Icons.brightness_6_outlined,
                  size: 24,
                  color: orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Тема: ${controller.labelRu()}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      height: 1.0,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    super.key,
    required this.icon,
    required this.text,
    this.height = 48,
    this.onTap,
    this.semanticsId,
  });

  final IconData icon;
  final String text;
  final double height;
  final VoidCallback? onTap;
  final String? semanticsId;

  static const orange = Color(0xFFFF5E1C);

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      identifier: semanticsId,
      button: true,
      label: text,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: orange, width: 1),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(icon, size: 24, color: orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      height: 1.0,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserVm {
  const _UserVm({
    required this.email,
    required this.name,
    required this.img,
    required this.isAdmin,
    required this.lang,
  });
  final String email;
  final String name;
  final String img;
  final bool isAdmin;
  final String lang;
}

class _LogoutConfirmDialog extends StatelessWidget {
  const _LogoutConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Внимание!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  height: 22 / 18,
                  letterSpacing: -0.41,
                  color: Color(0xFF282828),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Вы уверены, что хотите выйти из вашего аккаунта? Вы можете просто закрыть приложение',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF9D9D9D),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5E1C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        child: const Text(
                          'ВЫЙТИ',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 1.0,
                            letterSpacing: 0.4,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F1F1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'ОТМЕНА',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 1.0,
                            letterSpacing: 0.4,
                            color: Color(0xFF59523A),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSheet extends StatefulWidget {
  const _LanguageSheet({this.initialLang = 'ru', required this.desiredHeight});
  final String initialLang;
  final double desiredHeight;

  @override
  State<_LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<_LanguageSheet> {
  late String _selected = widget.initialLang;

  static const Color titleColor = Color(0xFF282828);
  static const double radius = 40;

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        height: widget.desiredHeight,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radius),
            topRight: Radius.circular(radius),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0D000000), // 3px -12px 20px #0000000D
              offset: Offset(3, -12),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // 👈 заголовок слева
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'ВЫБОР ЯЗЫКА',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          height: 23 / 24,
                          letterSpacing: 0,
                          color: titleColor,
                        ),
                      ),
                    ),
                    // крестик без фона, сам икон цвета #D6D6D6
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFFD6D6D6),
                      ),
                      splashRadius: 22,
                    ),
                  ],
                ),

                const SizedBox(height: 44),

                // общий левый 36: 20 боковых + 16 тут
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LangRow(
                        asset: 'assets/languages/russian.png',
                        title: 'Русский',
                        selected: _selected == 'ru',
                        onTap: () => setState(() => _selected = 'ru'),
                      ),
                      const SizedBox(height: 24),
                      _LangRow(
                        asset: 'assets/languages/english.png',
                        title: 'English',
                        selected: _selected == 'en',
                        onTap: () => setState(() => _selected = 'en'),
                      ),
                      const SizedBox(height: 24),
                      _LangRow(
                        asset: 'assets/languages/spanish.png',
                        title: 'Español',
                        selected: _selected == 'es',
                        onTap: () => setState(() => _selected = 'es'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48), // 👈 после испанского 48px

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF5E1C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 22),
                    ),
                    child: const Text(
                      'ОК',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.0,
                        letterSpacing: 0.48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // при необходимости можно добавить Spacer() ниже,
                // но по ТЗ кнопка идёт ровно после 48px.
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LangRow extends StatelessWidget {
  const _LangRow({
    required this.asset,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String asset;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = selected
        ? const Color(0xFFFF5E1C)
        : const Color(0xFF26351E);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          // круг 24x24 с картинкой по центру
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(asset, fit: BoxFit.cover),
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              height: 1.0,
              letterSpacing: 0,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
