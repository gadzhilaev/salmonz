import 'package:flutter/material.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import 'package:salmonz/data/models/models.dart';
import 'product_editor_page.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});
  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  static const titleDark = Color(0xFF26351E);
  static const orange = Color(0xFFFF5E1C);

  late Future<List<ProductModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = AppServices.instance.admin.listProducts(limit: 100);
  }

  Future<void> _reload() async {
    setState(() {
      _future = AppServices.instance.admin.listProducts(limit: 100);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: AppPageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AdminAppBar(onBack: () => Navigator.pop(context)),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Text(
                  'ВСЕ ТОВАРЫ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: titleDark,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  child: FutureBuilder<List<ProductModel>>(
                    future: _future,
                    builder: (context, snap) {
                      if (!snap.hasData &&
                          snap.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final items = snap.data ?? [];
                      return ListView.separated(
                        itemCount: items.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          if (i == items.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: ElevatedButton(
                                onPressed: () async {
                                  final ok = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ProductEditorPage(),
                                    ),
                                  );
                                  if (ok == true) await _reload();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orange,
                                  minimumSize: const Size.fromHeight(56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                ),
                                child: const Text(
                                  'ДОБАВИТЬ',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          }
                          final p = items[i];
                          return ListTile(
                            leading: (p.imageUrl ?? '').isEmpty
                                ? const Icon(Icons.image)
                                : Image.network(
                                    p.imageUrl!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  ),
                            title: Text(p.name),
                            subtitle: Text(
                              '${p.price.formatRub()} · ${p.isAvailable ? "в наличии" : "нет"}',
                            ),
                            onTap: () async {
                              final ok = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductEditorPage(existing: p),
                                ),
                              );
                              if (ok == true) await _reload();
                            },
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

class _AdminAppBar extends StatelessWidget {
  const _AdminAppBar({required this.onBack});
  final VoidCallback onBack;
  static const arrowColor = Color(0xFFCDCDCD);
  static const double hLogo = 62;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: hLogo + 26,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 20,
            top: 26,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: arrowColor,
              ),
            ),
          ),
          Positioned(
            top: 4,
            child: Image.asset(
              'assets/icon/logo_salmonz_small.png',
              width: 80,
              height: 62,
            ),
          ),
        ],
      ),
    );
  }
}
