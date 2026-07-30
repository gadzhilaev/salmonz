import 'package:flutter/material.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import 'package:salmonz/data/models/models.dart';

class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({super.key, required this.orderId});
  final String orderId;

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late Future<OrderModel> _future;
  static const arrowColor = Color(0xFFCDCDCD);
  static const titleDark = Color(0xFF26351E);
  static const double hLogo = 62;
  static const double ls24 = 0.96;

  @override
  void initState() {
    super.initState();
    _future = AppServices.instance.orders.get(widget.orderId);
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: AppPageContainer(
          child: Column(
            children: [
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
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: arrowColor,
                          ),
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
              Expanded(
                child: FutureBuilder<OrderModel>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Ошибка: ${snap.error}'));
                    }
                    final o = snap.data!;
                    return ListView(
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          o.publicNumber.isNotEmpty
                              ? o.publicNumber.toUpperCase()
                              : 'ЗАКАЗ',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            letterSpacing: ls24,
                            color: titleDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _fmtDate(o.createdAt),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Статус: ${_statusRu(o.status)}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Color(0xFFFF5E1C),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (o.addressText.isNotEmpty)
                          Text('Адрес: ${o.addressText}'),
                        Text('Телефон: ${o.phone}'),
                        if ((o.comment ?? '').isNotEmpty)
                          Text('Комментарий: ${o.comment}'),
                        const SizedBox(height: 24),
                        const Text(
                          'ПОЗИЦИИ',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: titleDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final item in o.items) ...[
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.productName),
                            subtitle: Text(
                              '${item.quantity} × ${item.unitPrice.formatRub()}',
                            ),
                            trailing: Text(item.lineTotal.formatRub()),
                          ),
                        ],
                        const Divider(),
                        Text('Товары: ${o.subtotal.formatRub()}'),
                        Text('Доставка: ${o.deliveryFee.formatRub()}'),
                        Text(
                          'Итого: ${o.total.formatRub()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
