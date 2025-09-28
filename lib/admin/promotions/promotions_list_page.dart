import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/promo.dart';
import 'promotion_editor_page.dart';

final supa = Supabase.instance.client;

class PromotionsListPage extends StatefulWidget {
  const PromotionsListPage({super.key});

  @override
  State<PromotionsListPage> createState() => _PromotionsListPageState();
}

class _PromotionsListPageState extends State<PromotionsListPage> {
  static const bg = Color(0xFFFFFFFF);
  static const arrowColor = Color(0xFFCDCDCD);
  static const titleDark = Color(0xFF26351E);
  static const tileBg = Color(0xFFFAFAFA);

  static const double hLogo = 62;
  static const double ls24 = 0.96;

  // ключ, чтобы пересоздавать подписку на стрим
  int _streamKey = 0;

  Stream<List<Promo>> _buildStream() {
    return supa
        .from('promotions')
        .stream(primaryKey: ['id'])
        .order('id', ascending: true)
        .map((rows) => rows
        .map<Promo>((m) => Promo(
      id: (m['id'] as num).toInt(),
      img: (m['img'] ?? '') as String,
    ))
        .where((p) => p.img.isNotEmpty)
        .toList());
  }

  Future<void> _refresh() async {
    // пересоздаём стрим: StreamBuilder получит новый key и переподпишется
    setState(() => _streamKey++);
    await Future<void>.delayed(const Duration(milliseconds: 250));
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
              // APPBAR
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
                      child: Image.asset(
                        'assets/icon/logo_salmonz_small.png',
                        width: 80, height: 62, fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'СПИСОК АКЦИЙ',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  height: 1.0,
                  letterSpacing: ls24,
                  color: titleDark,
                ),
              ),

              const SizedBox(height: 24),

              // Контент + pull-to-refresh
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: StreamBuilder<List<Promo>>(
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
                      final promos = snap.data!;
                      if (promos.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 160),
                            Center(child: Text('Акций пока нет')),
                          ],
                        );
                      }

                      return ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: promos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 28),
                        itemBuilder: (context, i) {
                          final p = promos[i];
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              // ждём результат редактора и при необходимости обновляем
                              final changed = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PromotionEditorPage(existing: p),
                                ),
                              );
                              if (changed == true && mounted) _refresh();
                            },
                            child: SizedBox(
                              width: double.infinity,
                              height: 554,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  color: tileBg, // #FAFAFA
                                  child: Image.network(
                                    p.img,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                    const Center(child: Icon(Icons.broken_image)),
                                  ),
                                ),
                              ),
                            ),
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

      // FAB «плюс» для добавления новой акции
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 24, bottom: 40),
        child: SizedBox(
          width: 60, height: 60,
          child: RawMaterialButton(
            onPressed: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const PromotionEditorPage()),
              );
              if (changed == true && mounted) _refresh();
            },
            fillColor: const Color(0xFFFF5E1C),
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