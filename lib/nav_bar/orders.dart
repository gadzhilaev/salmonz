// lib/nav_bar/orders.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/order_details_page.dart';
import '../widgets/app_nav_bar.dart';
import 'main_screen.dart';
import 'basket.dart';
import 'profile.dart';

final supa = Supabase.instance.client;

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<_OrdersVm> _future;

  static const bg = Colors.white;
  static const titleDark = Color(0xFF26351E);
  static const hintGray = Color(0xB2464646); // #464646B2
  static const tileBg = Color(0xFFFAFAFA);

  static const double hLogo = 62;
  static const double ls24 = 0.96; // 4% от 24
  static const double ls20 = 0.8;  // 4% от 20

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_OrdersVm> _load() async {
    final userId = supa.auth.currentUser?.id;
    if (userId == null) return const _OrdersVm(orders: [], imgByProductId: {});

    // 1) тянем заказы пользователя (самое нужное для экрана)
    final rows = await supa
        .from('orders')
        .select('id, created_at, product_list')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final orders = (rows as List).map((e) {
      return _OrderRow(
        id: (e['id'] as num).toInt(),
        createdAt: DateTime.parse(e['created_at'] as String),
        productIds: (e['product_list'] as List).map((x) => (x as num).toInt()).toList(),
      );
    }).toList();

    // 2) все уникальные product_id из всех заказов
    final ids = <int>{};
    for (final o in orders) { ids.addAll(o.productIds); }
    if (ids.isEmpty) return _OrdersVm(orders: orders, imgByProductId: const {});

    // 3) одним запросом подтянем изображения продуктов
    final prows = await supa
        .from('products')
        .select('id, img')
        .inFilter('id', ids.toList());

    final map = <int, String>{};
    for (final r in (prows as List)) {
      map[(r['id'] as num).toInt()] = (r['img'] ?? '') as String;
    }

    return _OrdersVm(orders: orders, imgByProductId: map);
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
                  width: 80, height: 62, fit: BoxFit.contain,
                ),
              ),

              // ниже — скроллим
              Expanded(
                child: FutureBuilder<_OrdersVm>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Ошибка: ${snap.error}'));
                    }
                    final vm = snap.data ?? const _OrdersVm(orders: [], imgByProductId: {});
                    if (vm.orders.isEmpty) {
                      return const Center(child: Text('Заказов пока нет'));
                    }

                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: vm.orders.length + 2, // + заголовок «ЗАКАЗЫ» и нижний отступ
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // отступ 24 + «ЗАКАЗЫ» + 24
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              const Text(
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
                              const SizedBox(height: 24),
                            ],
                          );
                        }
                        if (index == vm.orders.length + 1) {
                          return const SizedBox(height: 12);
                        }

                        final o = vm.orders[index - 1];
                        final imgs = o.productIds
                            .map((id) => vm.imgByProductId[id] ?? '')
                            .where((s) => s.isNotEmpty)
                            .toList();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => OrderDetailsPage(orderId: o.id)),
                              );
                            },
                            child: _OrderTile(
                              id: o.id,
                              createdAt: o.createdAt,
                              images: imgs,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: AppNavBar(
        current: AppTab.orders,
        onTap: (tab) {
          switch (tab) {
            case AppTab.home:
              Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const SuccessPage()),
              );
              break;
            case AppTab.orders:
              break;
            case AppTab.basket:
              Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const BasketPage()),
              );
              break;
            case AppTab.profile:
              Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
              break;
          }
        },
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
  static const hintGray = Color(0xB2464646); // #464646B2
  static const tileBg   = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок строки: "Заказ #ID" слева и дата справа
        Row(
          children: [
            Expanded(
              child: Text(
                'ЗАКАЗ #$id',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  height: 1.0,
                  letterSpacing: 0.8, // 4% от 20
                  color: titleDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _fmtDate(createdAt),
              textAlign: TextAlign.right,
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

        // Горизонтальная лента картинок заказа
        if (images.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < images.length; i++) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 120,
                      height: 80,
                      color: tileBg,
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
    );
  }

  static String _two(int n) => n < 10 ? '0$n' : '$n';
  static String _fmtDate(DateTime dt) {
    final d = dt.toLocal();
    return '${_two(d.day)}.${_two(d.month)}.${d.year} ${_two(d.hour)}:${_two(d.minute)}';
    // пример: 12.09.2025 23:47
  }
}

class _OrderRow {
  _OrderRow({
    required this.id,
    required this.createdAt,
    required this.productIds,
  });

  final int id;
  final DateTime createdAt;
  final List<int> productIds;
}

class _OrdersVm {
  const _OrdersVm({
    required this.orders,
    required this.imgByProductId,
  });

  final List<_OrderRow> orders;
  final Map<int, String> imgByProductId;
}