import '../../utils/ru_phone_formatter.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../pages/order_details_page.dart';

final supa = Supabase.instance.client;

class AdminUserDetailsPage extends StatefulWidget {
  const AdminUserDetailsPage({super.key, required this.userId});
  final String userId;

  @override
  State<AdminUserDetailsPage> createState() => _AdminUserDetailsPageState();
}

class _AdminUserDetailsPageState extends State<AdminUserDetailsPage> {
  static const bg = Color(0xFFFFFFFF);
  static const arrowColor = Color(0xFFCDCDCD);
  static const titleDark = Color(0xFF26351E);
  static const secondary = Color(0xFF282828);
  static const double hLogo = 62;
  static const double ls24 = 0.96;

  late Future<_Vm> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Vm> _load() async {
    // 1) профиль
    final u = await supa
        .from('user')
        .select('id,name,email,img,phone')
        .eq('id', widget.userId)
        .maybeSingle();

    final user = _UserVm(
      id: widget.userId,
      name: (u?['name'] ?? '') as String,
      email: (u?['email'] ?? '') as String,
      img: (u?['img'] ?? '') as String,
      phone: (u?['phone'] ?? '') as String,
    );

    // 2) заказы пользователя
    final rows = await supa
        .from('orders')
        .select('id, created_at, product_list')
        .eq('user_id', widget.userId)
        .order('created_at', ascending: false);

    final orders = (rows as List).map((e) {
      return _OrderRow(
        id: (e['id'] as num).toInt(),
        createdAt: DateTime.parse(e['created_at'] as String),
        productIds: (e['product_list'] as List).map((x) => (x as num).toInt()).toList(),
      );
    }).toList();

    // 3) подтянуть картинки для всех продуктов из заказов
    final ids = <int>{};
    for (final o in orders) {
      ids.addAll(o.productIds);
    }
    final map = <int, String>{};
    if (ids.isNotEmpty) {
      final prows = await supa
          .from('products')
          .select('id, img')
          .inFilter('id', ids.toList());
      for (final r in (prows as List)) {
        map[(r['id'] as num).toInt()] = (r['img'] ?? '') as String;
      }
    }

    return _Vm(user: user, orders: orders, imgByProductId: map);
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
              // --- APPBAR как в user_list_page ---
              SizedBox(
                height: hLogo + 26,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      left: 20, top: 26,
                      child: SizedBox(
                        width: 24, height: 24,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          splashRadius: 20,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: arrowColor),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      child: Image.asset(
                        'assets/icon/logo_salmonz_small.png',
                        width: 80, height: 62, fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- ТЕЛО: профиль + заказы в одном скролле ---
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _future = _load());
                    await _future;
                  },
                  child: FutureBuilder<_Vm>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(child: Text('Ошибка: ${snap.error}'));
                      }
                      final vm = snap.data ?? _Vm.empty();

                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        children: [
                          // --- Блок ПРОФИЛЬ ---
                          const Padding(
                            padding: EdgeInsets.only(left: 12),
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
                          const SizedBox(height: 24),

                          // аватар + имя/почта/телефон
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ClipOval(
                                  child: Container(
                                    width: 120, height: 120,
                                    color: const Color(0xFFEFEFEF),
                                    child: (vm.user.img.isNotEmpty)
                                        ? Image.network(vm.user.img, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 56, color: secondary))
                                        : const Icon(Icons.person, size: 56, color: secondary),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (vm.user.name.isNotEmpty ? vm.user.name : 'Без имени').toUpperCase(),
                                        maxLines: 2, overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                          height: 23/18,
                                          color: secondary,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        vm.user.email,
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                          height: 1.0,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                            () {
                                          final p = RuPhoneFormatter.pretty(vm.user.phone);
                                          return p.isEmpty ? '—' : p;
                                        }(),
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                          height: 1.0,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40), // 👈 отступ от картинки

                          // --- Блок ЗАКАЗЫ (как orders.dart, без нижней навигации) ---
                          const Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Text(
                              'ЗАКАЗЫ',
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

                          if (vm.orders.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Заказов пока нет'),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Column(
                                children: [
                                  for (int i = 0; i < vm.orders.length; i++) ...[
                                    _OrderTile(
                                      id: vm.orders[i].id,
                                      createdAt: vm.orders[i].createdAt,
                                      images: vm.orders[i].productIds
                                          .map((id) => vm.imgByProductId[id] ?? '')
                                          .where((s) => s.isNotEmpty)
                                          .toList(),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
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
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.id,
    required this.createdAt,
    required this.images,
  });

  final int id;
  final DateTime createdAt;
  final List<String> images;

  static const titleDark = Color(0xFF26351E);
  static const hintGray  = Color(0xB2464646);
  static const tileBg    = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailsPage(orderId: id)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Expanded(
                child: Text(
                  'ЗАКАЗ #$id',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    height: 1.0,
                    letterSpacing: 0.8,
                    color: titleDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _fmtDate(createdAt),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  height: 1.0,
                  color: hintGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Лента картинок
          if (images.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < images.length; i++) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 120, height: 80, color: tileBg,
                        child: Image.network(
                          images[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                    if (i != images.length - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _two(int n) => n < 10 ? '0$n' : '$n';
  static String _fmtDate(DateTime dt) {
    final d = dt.toLocal();
    return '${_two(d.day)}.${_two(d.month)}.${d.year} ${_two(d.hour)}:${_two(d.minute)}';
  }
}

class _Vm {
  _Vm({required this.user, required this.orders, required this.imgByProductId});
  final _UserVm user;
  final List<_OrderRow> orders;
  final Map<int, String> imgByProductId;

  factory _Vm.empty() => _Vm(user: _UserVm(id:'',name:'',email:'',img:'',phone:''), orders: const [], imgByProductId: const {});
}

class _UserVm {
  _UserVm({
    required this.id,
    required this.name,
    required this.email,
    required this.img,
    required this.phone,
  });
  final String id;
  final String name;
  final String email;
  final String img;
  final String phone;
}

class _OrderRow {
  _OrderRow({required this.id, required this.createdAt, required this.productIds});
  final int id;
  final DateTime createdAt;
  final List<int> productIds;
}