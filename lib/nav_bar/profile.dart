import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../profile/legal/legal_text_page.dart';
import '../profile/legal/legal_texts.dart';
import '../profile/edit_profile_page.dart';
import '../widgets/app_nav_bar.dart';
import 'main_screen.dart';
import 'orders.dart';
import 'basket.dart';
import '../profile/addresses_page.dart';
import '../auth/login.dart';
import '../profile/support_page.dart';
import '../admin/admin_panel_page.dart';

final supa = Supabase.instance.client;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<_UserVm> _future;
  final _nameKey = GlobalKey();   // ключ для текста имени
  double? _nameBottomDy;

  static const bg = Colors.white;
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
    final user = supa.auth.currentUser;
    if (user == null)
      return const _UserVm(email: '', name: '', img: '', isAdmin: false, lang: 'ru');

    final row = await supa
        .from('user')
        .select('name, img, email, is_admin, lang')
        .eq('id', user.id)
        .maybeSingle();

    final raw = row?['is_admin'];
    final isAdmin = (raw == true) ||
        (raw is num && raw != 0) ||
        (raw is String &&
            (raw.toLowerCase() == 't' || raw.toLowerCase() == 'true'));
    return _UserVm(
      email: (row?['email'] as String?) ?? (user.email ?? ''),
      name: (row?['name'] as String?) ?? '',
      img: (row?['img'] as String?) ?? '',
      isAdmin: isAdmin,
      lang: (row?['lang'] as String?) ?? 'ru',
    );
  }

  void _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LogoutConfirmDialog(),
    );
    if (ok == true) {
      await supa.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Login()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _future = _loadMe();
                    });
                    await _future;
                  },
                  child: FutureBuilder<_UserVm>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final me = snap.data ??
                          const _UserVm(
                              email: '', name: '', img: '', isAdmin: false, lang: 'ru');

                      return ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          const SizedBox(height: 24),

                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'ПРОФИЛЬ',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 24,
                                    height: 1.0,
                                    letterSpacing: ls24,
                                    color: titleDark,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _logout,
                                icon: const Icon(Icons.logout_outlined,
                                    size: 24, color: orange),
                                tooltip: 'Выйти',
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

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
                                                    const Icon(Icons.person,
                                                        size: 56,
                                                        color: secondary),
                                              )
                                            : const Icon(Icons.person,
                                                size: 56, color: secondary),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
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

                          _ProfileTile(
                            icon: Icons.account_circle_outlined,
                            text: 'Редактировать профиль',
                            onTap: () async {
                              final updated = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const EditProfilePage()),
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
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AddressesPage()),
                                );
                              },
                          ),
                          const SizedBox(height: 8),
                          _ProfileTile(
                            icon: Icons.translate_rounded,
                            text: 'Изменить язык',
                            onTap: _openLanguageSheet,
                          ),
                          const SizedBox(height: 8),
                          _ProfileTile(
                            icon: Icons.description_outlined,
                            text: 'Политика конфиденциальности',
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
                            icon: Icons.contact_support_outlined,
                            text: 'Написать в поддержку',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SupportPage()),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          if (me.isAdmin)
                            _ProfileTile(
                              icon: Icons.person_pin_circle_outlined,
                              text: 'Админ панель',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AdminPanelPage()),
                                );
                              },
                            ),
                          if (me.isAdmin) const SizedBox(height: 8),

                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppNavBar(
        current: AppTab.profile,
        onTap: (tab) {
          switch (tab) {
            case AppTab.home:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SuccessPage()),
              );
              break;
            case AppTab.orders:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const OrdersPage()),
              );
              break;
            case AppTab.basket:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const BasketPage()),
              );
              break;
            case AppTab.profile:
              break;
          }
        },
      ),
    );
  }
  // внутри _ProfilePageState:

  void _openLanguageSheet() async {
    final me = await _future;

    // зафиксируем актуальное положение имени на экране прямо сейчас
    _captureNameBottom();

    final mq = MediaQuery.of(context);
    // fallback если не удалось измерить (как раньше: до логотипа/заголовка)
    const double topGapFixed = 4 + 62 + 24;
    final double fallbackTop = mq.padding.top + topGapFixed;

    // верхняя кромка — это верх текста ИМЕНИ
    final double anchorTop = _nameBottomDy ?? fallbackTop;

    // высота шторки = высота экрана - положение якоря (имя)
    final double sheetHeight =
    (mq.size.height - anchorTop).clamp(300.0, mq.size.height);

    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LanguageSheet(
        initialLang: me.lang,
        desiredHeight: sheetHeight,
      ),
    );

    if (chosen != null && chosen != me.lang) {
      final uid = supa.auth.currentUser?.id;
      if (uid != null) {
        await supa.from('user').update({'lang': chosen}).eq('id', uid);
      }
      if (!mounted) return;
      setState(() {
        _future = _loadMe();
      });
      // переснимем после перестроения (на случай изменения верстки)
      WidgetsBinding.instance.addPostFrameCallback((_) => _captureNameBottom());
    }
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.text,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  static const orange = Color(0xFFFF5E1C);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        height: 48,
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
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  height: 1.0,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white, // #FFFFFF
      surfaceTintColor: Colors.transparent, // убираем розовый тинт
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 280,
          maxWidth: 280,
          minHeight: 172,
          maxHeight: 172,
        ),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Кнопка "Выйти" — как ОК (оранжевая)
                  SizedBox(
                    width: 116,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5E1C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      child: const Text(
                        'ВЫЙТИ',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          height: 1.0,
                          letterSpacing: 0.4, // 4% от 10
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Кнопка "Отмена" — серая
                  SizedBox(
                    width: 116,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F1F1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        elevation: 0,
                      ),
                      child: const Text(
                        'ОТМЕНА',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          height: 1.0,
                          letterSpacing: 0.4, // 4% от 10
                          color: Color(0xFF59523A),
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
  static const Color selectedColor = Color(0xFFFF5E1C);
  static const Color unselectedColor = Color(0xFF26351E);
  static const double radius = 40;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
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
            )
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 👈 заголовок слева
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
                          height: 23/24,
                          letterSpacing: 0,
                          color: titleColor,
                        ),
                      ),
                    ),
                    // крестик без фона, сам икон цвета #D6D6D6
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20, color: Color(0xFFD6D6D6)),
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
    final textColor = selected ? const Color(0xFFFF5E1C) : const Color(0xFF26351E);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          // круг 24x24 с картинкой по центру
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
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