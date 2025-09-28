import 'package:flutter/material.dart';
import 'product_editor_page.dart';

class ProductAdminViewPage extends StatelessWidget {
  const ProductAdminViewPage({super.key, required this.item});

  final dynamic item; // _ProdItem из admin_products_page.dart

  static const bg = Color(0xFFFFFFFF);
  static const arrowColor = Color(0xFFCDCDCD);
  static const titleDark = Color(0xFF26351E);
  static const tileBg = Color(0xFFFAFAFA);
  static const orange = Color(0xFFFF5E1C);
  static const double hLogo = 62;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, height: 260,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(color: tileBg),
                            Image.network(item.img, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                const Center(child: Icon(Icons.broken_image))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(item.name.toString().toUpperCase(),
                        style: const TextStyle(
                            fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w900,
                            height: 1.3, letterSpacing: 0.8, color: titleDark)),
                    const SizedBox(height: 8),
                    Text(
                      '${item.gramm} г.',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 18, color: Color(0xFF505050)),
                    ),
                    Text(
                      '${item.amount} шт.',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 18, color: Color(0xFF505050)),
                    ),
                    const SizedBox(height: 16),
                    if ((item.description as String).trim().isNotEmpty)
                      Text(item.description,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 16, height: 1.5, color: Color(0xFF505050))),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        SizedBox(
                          width: 173, height: 46,
                          child: ElevatedButton(
                            onPressed: () async {
                              final changed = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductEditorPage(existing: item),
                                ),
                              );
                              if (changed == true && context.mounted) Navigator.pop(context, true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orange,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                            ),
                            child: const Text('ИЗМЕНИТЬ',
                                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600,
                                    fontSize: 12, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Text('${_fmt(item.price)} ₽',
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(double v) => (v == v.roundToDouble()) ? v.toInt().toString() : v.toString();
}