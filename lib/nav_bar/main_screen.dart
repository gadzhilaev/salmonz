import 'package:flutter/material.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/data/models/models.dart';
import '../products_pages/products.dart';
import '../widgets/app_nav_bar.dart';
import 'orders.dart';
import 'basket.dart';
import 'profile.dart';

class SuccessPage extends StatefulWidget {
  const SuccessPage({super.key});

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {
  static const Color bgPage = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF26351E);
  static const Color orange = Color(0xFFFF5E1C);
  static const Color tileLight = Color(0xFFFAFAFA);

  late Future<_HomeData> _future;
  PageController? _promoPC;
  double _promoViewport = 1.0;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _promoPC?.dispose();
    super.dispose();
  }

  Future<_HomeData> _load() async {
    final catalog = AppServices.instance.catalog;
    final cats = await catalog.getCategories();
    final promos = await catalog.getPromotions();
    return _HomeData(categories: cats, promotions: promos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPage,
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
                  width: 80,
                  height: 62,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _future = _load());
                    await _future;
                  },
                  child: FutureBuilder<_HomeData>(
                    future: _future,
                    builder: (context, snap) {
                      if (!snap.hasData &&
                          snap.connectionState != ConnectionState.done) {
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

                      final data = snap.data ??
                          const _HomeData(categories: [], promotions: []);
                      final items = data.categories;

                      if (items.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 160),
                            Center(child: Text('Категорий пока нет')),
                          ],
                        );
                      }

                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 12),
                          _PromosSection(
                            promos: data.promotions,
                            controllerBuilder: (viewportFraction) {
                              if (_promoPC == null ||
                                  _promoViewport != viewportFraction) {
                                _promoPC?.dispose();
                                _promoViewport = viewportFraction;
                                _promoPC = PageController(
                                    viewportFraction: viewportFraction);
                              }
                              return _promoPC!;
                            },
                          ),
                          const SizedBox(height: 24),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const gap = 8.0;
                              final maxW = constraints.maxWidth;
                              final tileW = (maxW - gap) / 2;

                              return Wrap(
                                alignment: WrapAlignment.start,
                                crossAxisAlignment: WrapCrossAlignment.start,
                                runAlignment: WrapAlignment.start,
                                spacing: gap,
                                runSpacing: gap,
                                children: List.generate(items.length, (i) {
                                  final it = items[i];
                                  final isFirst = i == 0;
                                  return SizedBox(
                                    width: tileW,
                                    height: 160,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductsPage(
                                            title: it.name,
                                            categoryId: it.id,
                                          ),
                                        ),
                                      ),
                                      child: _CategoryCard(
                                        title: it.name,
                                        imagePath: it.imageUrl ?? '',
                                        radius: 12,
                                        bgColor: isFirst ? orange : tileLight,
                                        titleColor: isFirst
                                            ? Colors.white
                                            : textDark,
                                        fontWeight: isFirst
                                            ? FontWeight.w900
                                            : FontWeight.w700,
                                        letterSpacing: 0.72,
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ],
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
        current: AppTab.home,
        onTap: (tab) {
          switch (tab) {
            case AppTab.home:
              break;
            case AppTab.orders:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const OrdersPage()),
              );
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

class _HomeData {
  const _HomeData({required this.categories, required this.promotions});
  final List<CategoryModel> categories;
  final List<PromotionModel> promotions;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.imagePath,
    required this.radius,
    required this.bgColor,
    required this.titleColor,
    required this.fontWeight,
    required this.letterSpacing,
  });

  final String title;
  final String imagePath;
  final double radius;
  final Color bgColor;
  final Color titleColor;
  final FontWeight fontWeight;
  final double letterSpacing;

  bool get _isUrl => imagePath.startsWith('http');

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: bgColor),
          if (imagePath.isNotEmpty)
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomRight,
                child: _isUrl
                    ? Image.network(
                        imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.restaurant_menu_outlined),
                      )
                    : Image.asset(imagePath, fit: BoxFit.contain),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Text(
              title.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                height: 1.0,
                fontWeight: fontWeight,
                letterSpacing: letterSpacing,
                color: titleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromosSection extends StatelessWidget {
  const _PromosSection({
    required this.promos,
    required this.controllerBuilder,
  });

  final List<PromotionModel> promos;
  final PageController Function(double viewportFraction) controllerBuilder;

  static const double cardW = 220;
  static const double cardH = 330;
  static const double radius = 12;
  static const double between = 8;
  static const tileBg = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context) {
    final visible =
        promos.where((p) => (p.imageUrl ?? '').isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    final screenW = MediaQuery.of(context).size.width;
    const sidePadding = 12.0;
    final pageW = screenW - sidePadding * 2;
    final viewportFraction = ((cardW + between) / pageW).clamp(0.3, 1.0);
    final pc = controllerBuilder(viewportFraction);

    return SizedBox(
      height: cardH,
      child: PageView.builder(
        controller: pc,
        padEnds: false,
        itemCount: visible.length,
        itemBuilder: (context, index) {
          final isLast = index == visible.length - 1;
          return Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : between),
            child: SizedBox(
              width: cardW,
              height: cardH,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: ColoredBox(
                  color: tileBg,
                  child: ((visible[index].imageUrl ?? '').isEmpty)
                      ? const Center(
                          child: Icon(Icons.restaurant_menu_outlined),
                        )
                      : Image.network(
                          visible[index].imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.restaurant_menu_outlined),
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
