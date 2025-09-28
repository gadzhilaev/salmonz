// lib/legal/legal_text_page.dart
import 'package:flutter/material.dart';

class LegalTextPage extends StatelessWidget {
  const LegalTextPage({
    super.key,
    required this.caption, // заголовок (маленький жирный 14, UPPERCASE)
    required this.body,    // основной текст (12, Regular)
  });

  final String caption;
  final String body;

  static const bg = Color(0xFFFFFFFF);
  static const arrowColor = Color(0xFFCDCDCD);
  static const titleColor = Color(0xFF26351E);

  static const double hLogo = 62;
  static const double ls24 = 0.96; // 4% от 24px — для заголовка раздела (если понадобится)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          // общий горизонтальный отступ как в products.dart = 12,
          // но сам контент страницы — “колонка” с 16 по бокам (ниже через Padding)
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- ФИКСИРОВАННЫЙ APPBAR (стрелка + логотип) — 1в1 из products.dart ---
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

              // --- НИЖЕ — СКРОЛЛ ---
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 24),

                    // “Колонка” с боковыми отступами по 16
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Маленький заголовок 14 Bold UPPERCASE слева
                          Text(
                            caption.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              height: 23 / 14, // line-height: 23px
                              letterSpacing: 0,
                              color: Color(0xFF282828),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Основной текст 12 Regular
                          Text(
                            body,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              height: 21 / 12, // line-height: 21px
                              letterSpacing: 0,
                              color: Color(0xFF282828),
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}