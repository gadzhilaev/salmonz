// lib/admin/admin_orders_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//import '../pages/order_details_page.dart';
import 'admin_order_details_page.dart';

final supa = Supabase.instance.client;

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  late Future<_OrdersVm> _future;

  // стиль из админки
  static const bg = Color(0xFFFFFFFF);
  static const arrowColor = Color(0xFFCDCDCD);
  static const titleDark = Color(0xFF26351E);

  static const double hLogo = 62;
  static const double ls24 = 0.96; // 4% от 24

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_OrdersVm> _load() async {
    // 1) тянем ВСЕ заказы
    final rows = await supa
        .from('orders')
        .select('id, created_at, product_list')
        .order('created_at', ascending: false);

    final orders = (rows as List).map((e) {
      return _OrderRow(
        id: (e['id'] as num).toInt(),
        createdAt: DateTime.parse(e['created_at'] as String),
        productIds: (e['product_list'] as List).map((x) => (x as num).toInt()).toList(),
      );
    }).toList();

    // 2) собираем уникальные product_id
    final ids = <int>{};
    for (final o in orders) { ids.addAll(o.productIds); }

    if (ids.isEmpty) return _OrdersVm(orders: orders, imgByProductId: const {});

    // 3) одним запросом тянем картинки продуктов
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

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future; // дождёмся, чтобы индикатор спрятался красиво
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
              // --- APPBAR как в админке ---
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

              // дальше — скроллится
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: FutureBuilder<_OrdersVm>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 160),
                            Center(child: CircularProgressIndicator()),
                          ],
                        );
                      }
                      if (snap.hasError) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 160),
                            Center(child: Text('Ошибка: ${snap.error}')),
                          ],
                        );
                      }

                      final vm = snap.data ?? const _OrdersVm(orders: [], imgByProductId: {});
                      if (vm.orders.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 160),
                            Center(child: Text('Заказов пока нет')),
                          ],
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: vm.orders.length + 2, // + заголовок и нижний отступ
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // 24 + «ВСЕ ЗАКАЗЫ» + 24
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                SizedBox(height: 24),
                                Text(
                                  'ВСЕ ЗАКАЗЫ',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 24,
                                    height: 1.0,
                                    letterSpacing: ls24,
                                    color: titleDark,
                                  ),
                                ),
                                SizedBox(height: 24),
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
                                  MaterialPageRoute(
                                    builder: (_) => AdminOrderDetailsPage(orderId: o.id),
                                  ),
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
  static const hintGray = Color(0xB2464646); // #464646B2
  static const tileBg   = Color(0xFFFAFAFA);
  static const double ls20 = 0.8; // 4% от 20

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // заголовок строки
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
                  letterSpacing: ls20,
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