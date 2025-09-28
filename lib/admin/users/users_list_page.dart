import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_user_details_page.dart';

final supa = Supabase.instance.client;

class UsersListPage extends StatefulWidget {
  const UsersListPage({super.key});

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  static const bg = Color(0xFFFFFFFF);
  static const arrowColor = Color(0xFFCDCDCD);
  static const titleDark = Color(0xFF26351E);
  static const textGray = Color(0xFF717171);
  static const avatarBg = Color(0xFFEEEEEE);

  static const double hLogo = 62;
  static const double ls24 = 0.96; // 4% от 24px

  late Future<List<_UserRow>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_UserRow>> _load() async {
    // колонки: id, name, email, img, birthdate (DATE, может быть null)
    final res = await supa
        .from('user')
        .select('id,name,email,img,birthdate')
        .order('name', ascending: true);
    return (res as List).map((e) {
      final m = e as Map<String, dynamic>;
      DateTime? bd;
      final raw = m['birthdate'];
      if (raw is String && raw.isNotEmpty) {
        // supabase вернёт YYYY-MM-DD
        bd = DateTime.tryParse(raw);
      }
      return _UserRow(
        id: m['id'] as String,
        name: (m['name'] ?? '') as String,
        email: (m['email'] ?? '') as String,
        img: (m['img'] ?? '') as String,
        birthdate: bd,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- APPBAR как в admin_panel_page/products ---
              SizedBox(
                height: hLogo + 26,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      left: 20,
                      top: 26,
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          splashRadius: 20,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new,
                              size: 20, color: arrowColor),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      child: Image.asset(
                        'assets/icon/logo_salmonz_small.png',
                        width: 80,
                        height: 62,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- ЗАГОЛОВОК ---
              const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Text(
                  'ПОЛЬЗОВАТЕЛИ',
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

              const SizedBox(height: 24),

              // --- СПИСОК ---
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _future = _load(); // заново загружаем пользователей
                    });
                    await _future; // ждём загрузки
                  },
                  child: FutureBuilder<List<_UserRow>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(child: Text('Ошибка: ${snap.error}'));
                      }
                      final items = snap.data ?? [];
                      if (items.isEmpty) {
                        return const Center(child: Text('Пользователей нет'));
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _UserTile(
                          user: items[i],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminUserDetailsPage(userId: items[i].id),
                              ),
                            );
                          },
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
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, this.onTap});
  final _UserRow user;
  final VoidCallback? onTap;

  static const textDark = Color(0xFF282828);
  static const textGray = Color(0xFF717171);
  static const avatarBg = Color(0xFFEEEEEE);

  @override
  Widget build(BuildContext context) {
    String bd = 'не указана';
    if (user.birthdate != null) {
      final d = user.birthdate!;
      String two(int n) => n < 10 ? '0$n' : '$n';
      bd = '${two(d.day)}.${two(d.month)}.${d.year}';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // аватар
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 80, height: 80, color: avatarBg,
              child: (user.img.isNotEmpty)
                  ? Image.network(user.img, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.person))
                  : const Icon(Icons.person),
            ),
          ),
          const SizedBox(width: 12),
          // тексты
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (user.name.isEmpty ? 'БЕЗ ИМЕНИ' : user.name.toUpperCase()),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      height: 1.0,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.mail_outline, size: 12, color: textGray),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          user.email.isEmpty ? '—' : user.email,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                            height: 17/10,
                            color: textGray,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 12, color: textGray),
                      const SizedBox(width: 4),
                      Text(
                        bd,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                          height: 17/10,
                          color: textGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserRow {
  _UserRow({
    required this.id,
    required this.name,
    required this.email,
    required this.img,
    required this.birthdate,
  });

  final String id;
  final String name;
  final String email;
  final String img;
  final DateTime? birthdate;
}
