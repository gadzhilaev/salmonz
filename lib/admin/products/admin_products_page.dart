import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_admin_view_page.dart';
import 'product_editor_page.dart';

final supa = Supabase.instance.client;

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});
  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  static const bg = Color(0xFFFFFFFF);
  static const arrowColor = Color(0xFFCDCDCD);
  static const titleDark = Color(0xFF26351E);
  static const orange = Color(0xFFFF5E1C);
  static const double hLogo = 62;
  static const double ls24 = 0.96;

  int _streamKey = 0;

  Stream<List<_ProdItem>> _buildStream() {
    return supa
        .from('products')
        .stream(primaryKey: ['id'])
        .order('id', ascending: true)
        .map((rows) => rows.map<_ProdItem>((m) => _ProdItem.fromMap(m)).toList());
  }

  Future<void> _refresh() async {
    setState(() => _streamKey++);
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
              // appbar
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
                      child: Image.asset('assets/icon/logo_salmonz_small.png',
                          width: 80, height: 62, fit: BoxFit.contain),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Text('ВСЕ ТОВАРЫ',
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

              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: StreamBuilder<List<_ProdItem>>(
                    key: ValueKey(_streamKey),
                    stream: _buildStream(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 160),
                            Center(child: CircularProgressIndicator()),
                          ],
                        );
                      }
                      final items = snap.data!;
                      if (items.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 160),
                            Center(child: Text('Товаров пока нет')),
                          ],
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: items.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return const SizedBox(height: 0); // (у админки уже есть заголовок выше)
                          }
                          final p = items[index - 1];

                          return Column(
                            children: [
                              _AdminProductCard(
                                name: p.name,
                                description: p.description,
                                price: p.price,
                                imageUrl: p.img,
                                inStock: p.isStock,
                                onTap: () async {
                                  final changed = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(builder: (_) => ProductAdminViewPage(item: p)),
                                  );
                                  if (changed == true && mounted) _refresh();
                                },
                              ),
                              const SizedBox(height: 26),
                            ],
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

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 24, bottom: 40),
        child: SizedBox(
          width: 60, height: 60,
          child: RawMaterialButton(
            onPressed: () async {
              final changed = await Navigator.push<bool>(
                context, MaterialPageRoute(builder: (_) => const ProductEditorPage()),
              );
              if (changed == true && mounted) _refresh();
            },
            fillColor: orange,
            shape: const CircleBorder(),
            elevation: 0,
            child: const Icon(Icons.add, size: 24, color: Color(0xFFE8EAED)),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}

class _ProdItem {
  _ProdItem({
    required this.id,
    required this.name,
    required this.img,
    required this.description,
    required this.gramm,
    required this.amount,
    required this.price,
    required this.type,
    required this.isStock,
  });

  final int id;
  final String name;
  final String img;
  final String description;
  final int gramm;
  final int amount;
  final double price;
  final String type;   // категория (rolls/sushi/…)
  final bool isStock;

  factory _ProdItem.fromMap(Map m) => _ProdItem(
    id: (m['id'] as num).toInt(),
    name: (m['name'] ?? '') as String,
    img: (m['img'] ?? '') as String,
    description: (m['description'] ?? '') as String,
    gramm: (m['gramm'] as num?)?.toInt() ?? 0,
    amount: (m['amount'] as num?)?.toInt() ?? 0,
    price: (m['price'] as num?)?.toDouble() ?? 0,
    type: (m['type'] ?? '') as String,
    isStock: (m['is_stock'] is bool) ? m['is_stock'] as bool
        : ((m['is_stock'] as num?) ?? 1) != 0,
  );
}
class _AdminProductCard extends StatelessWidget {
  const _AdminProductCard({
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.inStock,
    required this.onTap,
  });

  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool inStock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const tileBg = Color(0xFFFAFAFA);
    const nameColor = Color(0xFF26351E);
    const descColor = Color(0xFF282828);
    const double ls18 = 0.72;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Картинка 369x260
          SizedBox(
            width: double.infinity,
            height: 260,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: tileBg),
                  Positioned.fill(
                    child: Opacity(
                      opacity: inStock ? 1.0 : 0.3,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                        const Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                  ),
                  if (!inStock)
                    const Center(
                      child: Text(
                        'НЕТ В НАЛИЧИИ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          height: 21 / 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Opacity(
            opacity: inStock ? 1.0 : 0.3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Название
                Text(
                  name.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: ls18,
                    color: nameColor,
                  ),
                ),

                // Описание
                if (description.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: descColor,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // ТОЛЬКО ЦЕНА (кнопки нет)
                Text(
                  '${_priceFmt(price)} ₽',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 20,
                    height: 1.0,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _priceFmt(double v) {
    final isInt = v == v.roundToDouble();
    return isInt ? v.toInt().toString() : v.toString();
  }
}