import 'package:flutter/material.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/responsive/app_breakpoints.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import 'package:salmonz/core/responsive/responsive_grid.dart';
import 'package:salmonz/core/theme/app_colors.dart';
import 'package:salmonz/core/theme/app_spacing.dart';
import 'package:salmonz/data/models/models.dart';
import 'package:salmonz/products_pages/products.dart';
import 'package:salmonz/widgets/app_empty_state.dart';
import 'package:salmonz/widgets/app_header.dart';
import 'package:salmonz/widgets/app_network_image.dart';
import 'package:salmonz/widgets/async_body.dart';

class SuccessPage extends StatefulWidget {
  const SuccessPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {
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
      appBar: const AppHeader.tab(title: 'Главная'),
      body: SafeArea(
        top: false,
        bottom: false,
        child: AppPageContainer(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _load());
              try {
                await _future;
              } catch (_) {}
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
                    try {
                      await _future;
                    } catch (_) {}
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
                          SizedBox(
                            height: 320,
                            child: AppEmptyState(
                              title: 'Меню пока пусто',
                              message: 'Категории появятся после обновления',
                              icon: Icons.restaurant_menu_outlined,
                            ),
                          ),
                        ],
                      );
                    }

                    final width = MediaQuery.sizeOf(context).width;
                    final scale = AppBreakpoints.typeScale(width);
                    final categoryHeight = width >= AppBreakpoints.compactMax
                        ? 190.0
                        : 156.0;

                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: AppSpacing.sm),
                        if (data.promotions.isNotEmpty) ...[
                          Text(
                            'Акции',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.sm),
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
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        Text(
                          'Меню',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ResponsiveGrid(
                          itemCount: items.length,
                          minCardWidth: width >= AppBreakpoints.compactMax
                              ? 280
                              : 140,
                          maxColumns: width >= AppBreakpoints.mediumMax
                              ? 4
                              : width >= AppBreakpoints.compactMax
                              ? 3
                              : 2,
                          itemHeight: categoryHeight,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          itemBuilder: (context, i, tileW) {
                            final it = items[i];
                            final isFirst = i == 0;
                            final isDark =
                                Theme.of(context).brightness == Brightness.dark;
                            final tileBg = isFirst
                                ? AppColors.orange
                                : (isDark
                                      ? AppColors.darkSurfaceElevated
                                      : AppColors.lightSurface);
                            final titleColor = isFirst
                                ? Colors.white
                                : (isDark
                                      ? AppColors.darkText
                                      : AppColors.forest);

                            return Material(
                              key: i == 0 ? const Key('homeCategory') : null,
                              color: tileBg,
                              elevation: isFirst ? 0 : 0.5,
                              shadowColor: Colors.black.withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadii.mdAll,
                                side: isFirst
                                    ? BorderSide.none
                                    : BorderSide(
                                        color: isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder,
                                      ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
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
                                  titleColor: titleColor,
                                  fontWeight: isFirst
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                  titleScale: scale,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    );
                  },
                );
              },
            ),
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
  if (s.contains('roll') || n.contains('ролл')) return 'assets/main/rolls.png';
  if (s.contains('set') || n.contains('сет')) return 'assets/main/sets.png';
  if (s.contains('sushi') || n.contains('суши')) return 'assets/main/sushi.png';
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
    required this.titleColor,
    required this.fontWeight,
    required this.titleScale,
  });

  final String title;
  final String? imageUrl;
  final String slug;
  final Color titleColor;
  final FontWeight fontWeight;
  final double titleScale;

  @override
  Widget build(BuildContext context) {
    final fallback = _categoryAssetFallback(slug, title);

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          right: -4,
          bottom: -4,
          left: 40,
          top: 36,
          child: AppNetworkImage(
            url: imageUrl,
            kind: AppImageKind.category,
            assetFallback: fallback,
            backgroundColor: Colors.transparent,
            memCacheWidth: 400,
          ),
        ),
        Positioned(
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          top: AppSpacing.sm,
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16 * titleScale,
              height: 1.15,
              fontWeight: fontWeight,
              color: titleColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _PromosSection extends StatelessWidget {
  const _PromosSection({required this.promos, required this.controllerBuilder});

  final List<PromotionModel> promos;
  final PageController Function(double viewportFraction) controllerBuilder;

  @override
  Widget build(BuildContext context) {
    if (promos.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final pageW = constraints.maxWidth;
        final bp = AppBreakpoints.ofWidth(MediaQuery.sizeOf(context).width);
        final isTablet = bp != AppBreakpoint.compact;

        final cardW = promos.length == 1
            ? pageW
            : (isTablet
                  ? (pageW * 0.72).clamp(320.0, 640.0)
                  : (pageW * 0.88).clamp(240.0, 360.0));
        // ~16:9-ish banner ratio for readable overlay text.
        final cardH = (cardW / 1.7).clamp(140.0, isTablet ? 260.0 : 200.0);
        const between = AppSpacing.sm;
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
                  borderRadius: AppRadii.mdAll,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(
                        url: promo.imageUrl,
                        kind: AppImageKind.banner,
                        assetFallback: AppNetworkImage.defaultPromoAsset,
                        memCacheWidth: 900,
                      ),
                      if (hasTitle)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(14, 28, 14, 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.55),
                                ],
                              ),
                            ),
                            child: Text(
                              promo.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize:
                                    15 *
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
