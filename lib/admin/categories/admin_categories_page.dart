import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../products_pages/products.dart';
import 'category_editor_page.dart';
import '../../utils/category.dart';

final supa = Supabase.instance.client;

class AdminCategoriesPage extends StatefulWidget {
  const AdminCategoriesPage({super.key});

  @override
  State<AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<AdminCategoriesPage> {
  // стили из админки
  static const bg = Color(0xFFFFFFFF);
  static const arrowColor = Color(0xFFCDCDCD);
  static const titleDark = Color(0xFF26351E);
  static const orange = Color(0xFFFF5E1C);
  static const tileLight = Color(0xFFFAFAFA);

  static const double hLogo = 62;
  static const double ls24 = 0.96;

  int _streamKey = 0;

  Stream<List<CategoryItem>> _buildStream() {
    return supa
        .from('categories')
        .stream(primaryKey: ['id'])
        .order('position', ascending: true)
        .map((rows) => rows.map<CategoryItem>((m) => CategoryItem(
      id: (m['id'] as num).toInt(),
      title: (m['title'] ?? '') as String,
      type: (m['type'] ?? '') as String,
      img: (m['img'] ?? '') as String,
      position: (m['position'] as num?)?.toInt() ?? 0,
    )).toList());
  }

  Future<void> _refresh() async {
    setState(() => _streamKey++);
    await Future<void>.delayed(const Duration(milliseconds: 200));
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
              // APPBAR из админки
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
                          icon: const Icon(Icons.arrow_back_ios_new,
                              size: 20, color: arrowColor),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      child: Image.asset(
                        'assets/icon/logo_salmonz_small.png',
                        width: 80, height: 62, fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Заголовок "Категории" (слева 12)
              const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Text(
                  'КАТЕГОРИИ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    height: 1.0,
                    letterSpacing: ls24, // 4%
                    color: titleDark,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: StreamBuilder<List<CategoryItem>>(
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
                            Center(child: Text('Категорий пока нет')),
                          ],
                        );
                      }

                      return ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          // Сетка категорий, выравнивание по левому краю
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const gap = 8.0;                       // промежуток между карточками
                              final maxW = constraints.maxWidth;
                              final tileW = (maxW - gap) / 2;        // две карточки в ряд

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
                                      onTap: () async {
                                        final changed = await Navigator.push<bool>(
                                          context,
                                          MaterialPageRoute(builder: (_) => CategoryEditorPage(existing: it)),
                                        );
                                        if (changed == true && mounted) _refresh();
                                      },
                                      onLongPress: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProductsPage(title: it.title, type: it.type),
                                          ),
                                        );
                                      },
                                      child: _CategoryCard(
                                        title: it.title,
                                        imagePath: it.img,
                                        radius: 12,
                                        bgColor: isFirst ? orange : tileLight,
                                        titleColor: isFirst ? Colors.white : titleDark,
                                        fontWeight: isFirst ? FontWeight.w900 : FontWeight.w700,
                                        letterSpacing: 0.72,
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
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

      // FAB «плюс» — добавить категорию
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 24, bottom: 40),
        child: SizedBox(
          width: 60, height: 60,
          child: RawMaterialButton(
            onPressed: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const CategoryEditorPage()),
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

/* ---- карточка как на главной ---- */
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
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomRight,
              child: _isUrl
                  ? Image.network(imagePath, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                  : Image.asset(imagePath, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            left: 16, right: 16, top: 16,
            child: Text(
              title.toUpperCase(),
              maxLines: 2, overflow: TextOverflow.ellipsis,
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