import 'package:flutter/material.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/network/api_exception.dart';
import 'package:salmonz/data/models/models.dart';

class AdminOrderDetailsPage extends StatefulWidget {
  const AdminOrderDetailsPage({super.key, required this.orderId});
  final String orderId;

  @override
  State<AdminOrderDetailsPage> createState() => _AdminOrderDetailsPageState();
}

class _AdminOrderDetailsPageState extends State<AdminOrderDetailsPage> {
  late Future<OrderModel> _future;

  static const statuses = [
    'NEW',
    'CONFIRMED',
    'PREPARING',
    'READY',
    'DELIVERING',
    'COMPLETED',
    'CANCELLED',
  ];

  @override
  void initState() {
    super.initState();
    _future = AppServices.instance.admin.getOrder(widget.orderId);
  }

  Future<void> _setStatus(String status) async {
    try {
      await AppServices.instance.admin.updateOrderStatus(
        widget.orderId,
        status,
      );
      setState(() {
        _future = AppServices.instance.admin.getOrder(widget.orderId);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Заказ')),
      body: FutureBuilder<OrderModel>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final o = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                o.publicNumber,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('Статус: ${o.status}'),
              Text('Телефон: ${o.phone}'),
              Text('Адрес: ${o.addressText}'),
              Text('Итого: ${o.total.formatRub()}'),
              const SizedBox(height: 16),
              const Text('Сменить статус:'),
              Wrap(
                spacing: 8,
                children: statuses
                    .map(
                      (s) => ActionChip(
                        label: Text(s),
                        onPressed: () => _setStatus(s),
                      ),
                    )
                    .toList(),
              ),
              const Divider(),
              for (final item in o.items)
                ListTile(
                  title: Text(item.productName),
                  subtitle: Text(
                    '${item.quantity} × ${item.unitPrice.formatRub()}',
                  ),
                  trailing: Text(item.lineTotal.formatRub()),
                ),
            ],
          );
        },
      ),
    );
  }
}
