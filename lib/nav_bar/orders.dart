import 'package:flutter/material.dart';
import 'package:salmonz/core/network/api_exception.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/responsive/app_breakpoints.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import 'package:salmonz/data/models/models.dart';
import '../pages/order_details_page.dart';
import '../widgets/app_error_view.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<OrderModel>> _future;
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
    final scale = AppBreakpoints.typeScale(MediaQuery.sizeOf(context).width);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: AppPageContainer(
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
                    try {
                      await _future;
                    } catch (_) {}
                  },
                  child: FutureBuilder<List<OrderModel>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(
                          child: AppErrorView(
                            message: ApiException.userMessageFrom(snap.error!),
                            onRetry: () {
                              setState(() {
                                _future = AppServices.instance.orders.list();
                              });
                            },
                          ),
                        );
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
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 24),
                                Text(
                                  'ЗАКАЗЫ',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 24 * scale,
                                    letterSpacing: ls24,
                                    color: titleDark,
                                  ),
                                ),
                                const SizedBox(height: 24),
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
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16 * scale,
                                        color: titleDark,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _fmtDate(o.createdAt),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14 * scale,
                                        color: const Color(0xFF282828),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${_statusRu(o.status)} · ${o.total.formatRub()}',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14 * scale,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFFFF5E1C),
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
    );
  }
}
