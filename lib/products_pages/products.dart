import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'product.dart';
import '../widgets/cart.dart';

final supa = Supabase.instance.client;

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key, required this.title, required this.type});
  final String title; // заголовок (РОЛЛЫ, СУШИ и т.д.)
  final String type; // тип для фильтра (rolls, sushi и т.д.)

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadProducts(widget.type);
  }

  Future<List<Product>> _loadProducts(String type) async {
    final t = type.trim(); // на всякий
    final res = await supa
        .from('products')
        .select('id,name,description,price,img,type,gramm,amount,is_stock')
    // ILIKE — регистронезависимое сравнение.
    // Без % это "равно без учёта регистра".
        .ilike('type', t)
        .order('id', ascending: true);

    return (res as List)
        .map((m) => Product.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFFFFFF);
    const arrowColor = Color(0xFFCDCDCD);
    const titleColor = Color(0xFF26351E);

    const double hLogo = 62;
    const double ls24 = 0.96; // 4% от 24px

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- ФИКСИРОВАННЫЙ APPBAR (стрелка + логотип) ---
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
                          icon: const Icon(Icons.arrow_back_ios_new,
                              size: 20, color: arrowColor),
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

              // --- ВСЁ НИЖЕ — СКРОЛЛИТСЯ ---
              Expanded(
                child: FutureBuilder<List<Product>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Ошибка: ${snap.error}'));
                    }
                    final items = snap.data ?? [];
                    if (items.isEmpty) {
                      return const Center(child: Text('Ничего не найдено'));
                    }

                    // Один ListView: первым элементом идёт заголовок раздела, далее продукты.
                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: items.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // Заголовок + отступ 24 (после логотипа) + ещё 24 до первого товара
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                  letterSpacing: ls24,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          );
                        }

                        final p = items[index - 1];

                        // Карточка товара + разделитель 26 (кроме последнего)
                        return Column(
                          children: [
                            _ProductCard(
                              id: p.id,
                              name: p.name,
                              description: p.description,
                              price: p.price,
                              imageUrl: p.img,
                              inStock: p.isStock,
                              onTap: p.isStock ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductPage(
                                      id: p.id,
                                      name: p.name,
                                      img: p.img,
                                      description: p.description,
                                      gramm: p.gramm,
                                      amount: p.amount,
                                      price: p.price,
                                    ),
                                  ),
                                );
                              } : null,
                            ),
                            const SizedBox(height: 26),
                          ],
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
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.inStock,     // 👈
    this.onTap,
  });

  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool inStock;          // 👈
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const tileBg = Color(0xFFFAFAFA);
    const nameColor = Color(0xFF26351E);
    const descColor = Color(0xFF282828);
    const btnBg = Color(0xFFFF5E1C);
    const double ls18 = 0.72;

    return InkWell(
      onTap: onTap, // null если нет в наличии — не реагирует
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
                  // картинка — 30% если нет в наличии
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
                  // лейбл поверх — всегда 100% непрозрачности
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
                          letterSpacing: 0,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 👇 ВСЯ НИЖНЯЯ ЧАСТЬ КАРТОЧКИ СТАНОВИТСЯ ПРОЗРАЧНЕЕ, ЕСЛИ НЕТ В НАЛИЧИИ
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
                      letterSpacing: 0,
                      color: descColor,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Кнопка + цена
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 173,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: inStock
                            ? () {
                          Cart.instance.add(CartItem(
                            id: id,
                            name: name,
                            img: imageUrl,
                            price: price,
                            gramm: 0,
                            amount: 1,
                            qty: 1,
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Добавлено в корзину')),
                          );
                        }
                            : null, // disabled если нет в наличии
                        style: ElevatedButton.styleFrom(
                          backgroundColor: btnBg,
                          disabledBackgroundColor:
                          const Color(0xFFFF5E1C).withOpacity(0.4),
                          disabledForegroundColor: Colors.white.withOpacity(0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text(
                          'ДОБАВИТЬ В КОРЗИНУ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            height: 1.0,
                            letterSpacing: 0.4,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
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

class Product {
  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.img,
    required this.type,
    required this.gramm,
    required this.amount,
    required this.isStock,
  });

  final int id;
  final String name;
  final String description;
  final double price;
  final String img;
  final String type;
  final int gramm;
  final int amount;
  final bool isStock;

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        id: (m['id'] as num).toInt(),
        name: (m['name'] ?? '') as String,
        description: (m['description'] ?? '') as String,
        price: (m['price'] as num).toDouble(),
        img: (m['img'] ?? '') as String,
        type: (m['type'] ?? '') as String,
        gramm: (m['gramm'] as num).toInt(), // 👈
        amount: (m['amount'] as num).toInt(),
        isStock: () {
          final v = m['is_stock'];
          if (v is bool) return v;
          if (v is num) return v != 0;
          if (v is String)
            return v.toLowerCase() == 'true' ||
                v.toLowerCase() == 't' ||
                v == '1';
          return true; // дефолт: в наличии
        }(),
      );
}
