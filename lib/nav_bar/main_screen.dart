import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../products_pages/products.dart';
import '../widgets/app_nav_bar.dart';
import 'orders.dart';
import 'basket.dart';
import 'profile.dart';

final supa = Supabase.instance.client;

class SuccessPage extends StatefulWidget {
  const SuccessPage({super.key});

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> with WidgetsBindingObserver {
  static const Color bgPage   = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF26351E);
  static const Color orange   = Color(0xFFFF5E1C);
  static const Color tileLight= Color(0xFFFAFAFA);

  late Stream<List<_CatItem>> _catsStream;
  int _streamKey = 0;
  List<_CatItem>? _overrideItems;

  // --- ПРОМО ---
  late final Stream<List<_Promo>> _promosStream;
  PageController? _promoPC;
  double _promoViewport = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Категории (как было)
    _catsStream = Supabase.instance.client
        .from('categories')
        .stream(primaryKey: ['id'])
        .order('position', ascending: true)
        .map((rows) {
      final list = rows.map<_CatItem>((m) => _CatItem(
        title: (m['title'] ?? '') as String,
        type:  (m['type']  ?? '') as String,
        imagePath: (m['img'] ?? '') as String,
        position: (m['position'] as num?)?.toInt() ?? 0,
      )).toList();
      list.sort((a, b) => a.position.compareTo(b.position));
      return list;
    });

    // Акции
    _promosStream = Supabase.instance.client
        .from('promotions')
        .stream(primaryKey: ['id'])
        .order('id', ascending: true)
        .map((rows) => rows.map<_Promo>((m) => _Promo(
      id: (m['id'] as num).toInt(),
      img: (m['img'] ?? '') as String,
    )).where((p) => p.img.isNotEmpty).toList());
  }

  @override
  void dispose() {
    _promoPC?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<List<_CatItem>> _fetchOnce() async {
    final res = await supa
        .from('categories')
        .select('title,type,img,position')
        .order('position', ascending: true);

    final list = (res as List).map((e) {
      final m = e as Map<String, dynamic>;
      return _CatItem(
        title: (m['title'] ?? '') as String,
        type: (m['type']  ?? '') as String,
        imagePath: (m['img']  ?? '') as String,
        position: (m['position'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    list.sort((a, b) => a.position.compareTo(b.position));
    return list;
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
                  width: 80, height: 62, fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: RefreshIndicator(
                  // «потянуть вниз»: просто подождём анимацию; стрим сам подтянет свежие данные
                  onRefresh: () async {
                    final fresh = await _fetchOnce();     // разовый SELECT
                    if (!mounted) return;
                    setState(() {
                      _overrideItems = fresh;             // сразу показываем свежие данные
                      _streamKey++;                       // пересоздаём подписку на стрим
                    });
                  },
                  child: StreamBuilder<List<_CatItem>>(
                    key: ValueKey(_streamKey),    // <— пересоздаёт подписку
                    stream: _catsStream,
                    builder: (context, snap) {
                      // пока нет данных — индикатор
                      if (!snap.hasData && _overrideItems == null) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 160),
                            Center(child: CircularProgressIndicator()),
                          ],
                        );
                      }

                      // берём override если есть, иначе данные из стрима
                      final items = _overrideItems ?? (snap.data ?? const <_CatItem>[]);

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
                          // --- 24px после логотипа ---
                          const SizedBox(height: 12),

                          // --- АКЦИИ ---
                          _PromosSection(
                            stream: _promosStream,
                            controllerBuilder: (viewportFraction) {
                              if (_promoPC == null || _promoViewport != viewportFraction) {
                                _promoPC?.dispose();
                                _promoViewport = viewportFraction;
                                _promoPC = PageController(viewportFraction: viewportFraction);
                              }
                              return _promoPC!;
                            },
                          ),

                          // --- 24px после акций ---
                          const SizedBox(height: 24),

                          // --- КАТЕГОРИИ (как у тебя было) ---
                          // --- КАТЕГОРИИ (левый край) ---
                          LayoutBuilder(
                            builder: (context, constraints) {
                              // отступы экрана уже заданы внешним Padding(horizontal: 12)
                              const gap = 8.0;               // промежуток между карточками
                              final maxW = constraints.maxWidth;
                              final tileW = (maxW - gap) / 2; // 2 карточки в ряд

                              return Wrap(
                                alignment: WrapAlignment.start,       // выравнивание по левому краю
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
                                          builder: (_) => ProductsPage(title: it.title, type: it.type),
                                        ),
                                      ),
                                      child: _CategoryCard(
                                        title: it.title,
                                        imagePath: it.imagePath,
                                        radius: 12,
                                        bgColor: isFirst ? orange : tileLight,
                                        titleColor: isFirst ? Colors.white : textDark,
                                        fontWeight: isFirst ? FontWeight.w900 : FontWeight.w700,
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
                context, MaterialPageRoute(builder: (_) => const OrdersPage()),
              );
              break;
            case AppTab.basket:
              Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const BasketPage()),
              );
              break;
            case AppTab.profile:
              Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
              break;
          }
        },
      ),
    );
  }
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
  final String imagePath; // может быть URL или asset-путь
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
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomRight,
              child: _isUrl
                  ? Image.network(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
              )
                  : Image.asset(imagePath, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            left: 16, right: 16, top: 16,
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

class _CatItem {
  const _CatItem({
    required this.title,
    required this.type,
    required this.imagePath,
    required this.position,
  });
  final String title;
  final String type;
  final String imagePath;
  final int position;
}

class _Promo {
  const _Promo({required this.id, required this.img});
  final int id;
  final String img;
}

class _PromosSection extends StatelessWidget {
  const _PromosSection({
    required this.stream,
    required this.controllerBuilder,
  });

  final Stream<List<_Promo>> stream;
  final PageController Function(double viewportFraction) controllerBuilder;

  static const double cardW = 220;
  static const double cardH = 330;
  static const double radius = 12;
  static const double between = 8;               // расстояние между карточками
  static const tileBg = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    const sidePadding = 12.0;                     // внешний паддинг экрана
    final pageW = screenW - sidePadding * 2;

    // важный момент: учитываем межкарточный зазор в ширине "страницы"
    final viewportFraction = ((cardW + between) / pageW).clamp(0.3, 1.0);

    return StreamBuilder<List<_Promo>>(
      stream: stream,
      builder: (context, snap) {
        if (!snap.hasData || (snap.data?.isEmpty ?? true)) {
          return const SizedBox.shrink();
        }
        final promos = snap.data!;
        final pc = controllerBuilder(viewportFraction);

        return SizedBox(
          height: cardH,
          child: PageView.builder(
            controller: pc,
            padEnds: false,                        // без внутренних "ушей"
            itemCount: promos.length,
            itemBuilder: (context, index) {
              final isLast = index == promos.length - 1;
              return Padding(
                // слева всегда 0 (левый край задаёт внешний Padding=12),
                // межкарточный зазор отдаём ПРАВОЙ стороне текущей карточки
                padding: EdgeInsets.only(right: isLast ? 0 : between),
                child: SizedBox(
                  width: cardW,
                  height: cardH,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: ColoredBox(
                      color: tileBg,
                      child: Image.network(
                        promos[index].img,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                        const Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
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