import 'package:flutter/material.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/data/models/models.dart';
import '../pages/order_details_page.dart';
import '../widgets/app_nav_bar.dart';
import 'main_screen.dart';
import 'basket.dart';
import 'profile.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<OrderModel>> _future;

  static const bg = Colors.white;
  static const titleDark = Color(0xFF26351E);
  static const double ls24 = 0.96;

  @override
  void initState() {
    super.initState();
    _future = AppServices.instance.orders.list();
  }

  static String _two(int n) => n < 10 ? '0$n' : '$n';
  static String _fmtDate(DateTime dt) {
    final d = dt.toLocal();
    return '${_two(d.day)}.${_two(d.month)}.${d.year} ${_two(d.hour)}:${_two(d.minute)}';
  }

  static String _statusRu(String status) {
    switch (status.toUpperCase()) {
      case 'NEW':
        return 'Новый';
      case 'CONFIRMED':
        return 'Подтверждён';
      case 'PREPARING':
        return 'Готовится';
      case 'READY':
        return 'Готов';
      case 'DELIVERING':
        return 'Доставляется';
      case 'COMPLETED':
        return 'Завершён';
      case 'CANCELLED':
        return 'Отменён';
      default:
        return status;
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
                      _future = AppServices.instance.orders.list();
                    });
                    await _future;
                  },
                  child: FutureBuilder<List<OrderModel>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(child: Text('Ошибка: ${snap.error}'));
                      }
                      final orders = snap.data ?? [];
                      if (orders.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 160),
                            Center(child: Text('Заказов пока нет')),
                          ],
                        );
                      }

                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: orders.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 24),
                                Text(
                                  'ЗАКАЗЫ',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 24,
                                    letterSpacing: ls24,
                                    color: titleDark,
                                  ),
                                ),
                                SizedBox(height: 24),
                              ],
                            );
                          }
                          final o = orders[index - 1];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        OrderDetailsPage(orderId: o.id),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAFAFA),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      o.publicNumber.isNotEmpty
                                          ? o.publicNumber
                                          : 'Заказ',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: titleDark,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _fmtDate(o.createdAt),
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        color: Color(0xFF282828),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${_statusRu(o.status)} · ${o.total.formatRub()}',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFFFF5E1C),
                                      ),
                                    ),
                                  ],
                                ),
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
      bottomNavigationBar: AppNavBar(
        current: AppTab.orders,
        onTap: (tab) {
          switch (tab) {
            case AppTab.home:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SuccessPage()),
              );
              break;
            case AppTab.orders:
              break;
            case AppTab.basket:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const BasketPage()),
              );
              break;
            case AppTab.profile:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
              break;
          }
        },
      ),
    );
  }
}
