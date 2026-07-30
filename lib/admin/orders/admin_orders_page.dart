import 'package:flutter/material.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import 'package:salmonz/data/models/models.dart';
import 'admin_order_details_page.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  late Future<List<OrderModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = AppServices.instance.admin.listOrders(limit: 100);
  }

  Future<void> _reload() async {
    setState(() {
      _future = AppServices.instance.admin.listOrders(limit: 100);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Заказы')),
      body: AppPageContainer(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: FutureBuilder<List<OrderModel>>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final orders = snap.data!;
              if (orders.isEmpty) {
                return ListView(
                  children: const [
                    SizedBox(height: 120),
                    Center(child: Text('Заказов нет')),
                  ],
                );
              }
              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (_, i) {
                  final o = orders[i];
                  return ListTile(
                    title: Text(o.publicNumber),
                    subtitle: Text('${o.status} · ${o.total.formatRub()}'),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminOrderDetailsPage(orderId: o.id),
                        ),
                      );
                      await _reload();
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
