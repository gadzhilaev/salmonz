import 'package:flutter/material.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/responsive/app_breakpoints.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import 'package:salmonz/core/responsive/responsive_grid.dart';
import 'package:salmonz/data/models/models.dart';
import 'package:salmonz/products_pages/products.dart';
import 'package:salmonz/widgets/app_network_image.dart';
import 'package:salmonz/widgets/async_body.dart';

class SuccessPage extends StatefulWidget {
  const SuccessPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: AppPageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      return AsyncBody<_HomeData>(
                        snapshot: snap,
                        scrollable: true,
                        waitForData: true,
                        onRetry: () async {
                          setState(() => _future = _load());
                          await _future;
                        },
                        loading: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 160),
                            Center(child: CircularProgressIndicator()),
                          ],
                        ),
                        builder: (data) {
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

                          final width = MediaQuery.sizeOf(context).width;
                          final scale = AppBreakpoints.typeScale(width);
                          final categoryHeight =
                              width >= AppBreakpoints.compactMax
                              ? 190.0
                              : 160.0;

                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 12),
                              if (data.promotions.isNotEmpty) ...[
                                Text(
                                  'АКЦИИ',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20 * scale,
                                    letterSpacing: 0.8,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onSurface
                                        : textDark,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _PromosSection(
                                  promos: data.promotions,
                                  controllerBuilder: (viewportFraction) {
                                    if (_promoPC == null ||
                                        _promoViewport != viewportFraction) {
                                      _promoPC?.dispose();
                                      _promoViewport = viewportFraction;
                                      _promoPC = PageController(
                                        viewportFraction: viewportFraction,
                                      );
                                    }
                                    return _promoPC!;
                                  },
                                ),
                                const SizedBox(height: 24),
                              ],
                              Text(
                                'МЕНЮ',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20 * scale,
                                  letterSpacing: 0.8,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(context).colorScheme.onSurface
                                      : textDark,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ResponsiveGrid(
                                itemCount: items.length,
                                minCardWidth: width >= AppBreakpoints.compactMax
                                    ? 300
                                    : 240,
                                maxColumns: width >= AppBreakpoints.mediumMax
                                    ? 4
                                    : 3,
                                itemHeight: categoryHeight,
                                itemBuilder: (context, i, tileW) {
                                  final it = items[i];
                                  final isFirst = i == 0;
                                  final isDark =
                                      Theme.of(context).brightness ==
                                      Brightness.dark;
                                  final tileBg = isDark
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest
                                      : tileLight;
                                  final mutedTitle = isDark
                                      ? Theme.of(context).colorScheme.onSurface
                                      : textDark;

                                  return InkWell(
                                    key: i == 0
                                        ? const Key('homeCategory')
                                        : null,
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
                                      imageUrl: it.imageUrl,
                                      slug: it.slug,
                                      radius: 12,
                                      bgColor: isFirst ? orange : tileBg,
                                      titleColor: isFirst
                                          ? Colors.white
                                          : mutedTitle,
                                      fontWeight: isFirst
                                          ? FontWeight.w900
                                          : FontWeight.w700,
                                      letterSpacing: 0.72,
                                      titleScale: scale,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
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
    );
  }
}

class _HomeData {
  const _HomeData({required this.categories, required this.promotions});
  final List<CategoryModel> categories;
  final List<PromotionModel> promotions;
}

String _categoryAssetFallback(String slug, String name) {
  final s = slug.toLowerCase();
  final n = name.toLowerCase();
  if (s.contains('roll') || n.contains('ролл')) {
    return 'assets/main/rolls.png';
  }
  if (s.contains('set') || n.contains('сет')) {
    return 'assets/main/sets.png';
  }
  if (s.contains('sushi') || n.contains('суши')) {
    return 'assets/main/sushi.png';
  }
  if (s.contains('drink') ||
      s.contains('bottle') ||
      n.contains('напит') ||
      n.contains('бутыл')) {
    return 'assets/main/bootls.png';
  }
  if (s.contains('sauce') || s.contains('sous') || n.contains('соус')) {
    return 'assets/main/souses.png';
  }
  if (s.contains('cake') || n.contains('торт') || n.contains('десерт')) {
    return 'assets/main/cakes.png';
  }
  if (s.contains('lapsha') || s.contains('noodle') || n.contains('лапш')) {
    return 'assets/main/lapsha.png';
  }
  if (s.contains('zakusk') || n.contains('закуск')) {
    return 'assets/main/zakuski.png';
  }
  return AppNetworkImage.defaultCategoryAsset;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.imageUrl,
    required this.slug,
    required this.radius,
    required this.bgColor,
    required this.titleColor,
    required this.fontWeight,
    required this.letterSpacing,
    required this.titleScale,
  });

  final String title;
  final String? imageUrl;
  final String slug;
  final double radius;
  final Color bgColor;
  final Color titleColor;
  final FontWeight fontWeight;
  final double letterSpacing;
  final double titleScale;

  @override
  Widget build(BuildContext context) {
    final fallback = _categoryAssetFallback(slug, title);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: bgColor),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomRight,
              child: AppNetworkImage(
                url: imageUrl,
                fit: BoxFit.contain,
                assetFallback: fallback,
              ),
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
                fontSize: 18 * titleScale,
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
  const _PromosSection({required this.promos, required this.controllerBuilder});

  final List<PromotionModel> promos;
  final PageController Function(double viewportFraction) controllerBuilder;

  static const double radius = 12;
  static const double between = 12;
  static const tileBg = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context) {
    if (promos.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final pageW = constraints.maxWidth;
        final bp = AppBreakpoints.ofWidth(MediaQuery.sizeOf(context).width);
        final isTablet = bp != AppBreakpoint.compact;

        // Single promo fills most of the row; multiple stay carousel-sized.
        final cardW = promos.length == 1
            ? pageW
            : (isTablet
                  ? (pageW * 0.72).clamp(320.0, 640.0)
                  : (pageW * 0.85).clamp(220.0, 360.0));
        final cardH = isTablet ? 280.0 : 220.0;
        final viewportFraction = promos.length == 1
            ? 1.0
            : ((cardW + between) / pageW).clamp(0.45, 0.95);
        final pc = controllerBuilder(viewportFraction);

        return SizedBox(
          height: cardH,
          width: pageW,
          child: PageView.builder(
            controller: pc,
            padEnds: false,
            itemCount: promos.length,
            itemBuilder: (context, index) {
              final promo = promos[index];
              final isLast = index == promos.length - 1;
              final hasTitle = promo.title.trim().isNotEmpty;

              return Padding(
                padding: EdgeInsets.only(
                  right: promos.length == 1 || isLast ? 0 : between,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: tileBg,
                        child: AppNetworkImage(
                          url: promo.imageUrl,
                          fit: BoxFit.cover,
                          assetFallback: AppNetworkImage.defaultPromoAsset,
                        ),
                      ),
                      if (hasTitle)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.65),
                                ],
                              ),
                            ),
                            child: Text(
                              promo.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                fontSize:
                                    16 *
                                    AppBreakpoints.typeScale(
                                      MediaQuery.sizeOf(context).width,
                                    ),
                                height: 1.2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
