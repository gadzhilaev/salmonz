import 'package:flutter/material.dart';
import 'users/users_list_page.dart';
import 'promotions/promotions_list_page.dart';
import 'orders/admin_orders_page.dart';
import 'categories/admin_categories_page.dart';
import 'products/admin_products_page.dart';

class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  // цвета/константы как в products.dart
  static const bg = Color(0xFFFFFFFF);
  static const arrowColor = Color(0xFFCDCDCD);
  static const titleDark = Color(0xFF26351E);
  static const orange = Color(0xFFFF5E1C);

  static const double hLogo = 62;
  static const double ls24 = 0.96; // 4% от 24

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
              // --- APPBAR как в products.dart ---
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

              // --- ЗАГОЛОВОК ---
              const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Text(
                  'АДМИН ПАНЕЛЬ',
                  // Inter Black 24, 100%, letter-spacing 4%, CAPS
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    height: 1.0,
                    letterSpacing: ls24, // 4%
                    color: titleDark, // #26351E
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --- СПИСОК КНОПОК ---
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // admin_panel_page.dart (фрагмент внутри ListView)
                    _AdminTile(
                      text: 'Список акций',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PromotionsListPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _AdminTile(
                      text: 'Список пользователей',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UsersListPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _AdminTile(
                      text: 'Список заказов',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminOrdersPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _AdminTile(
                      text: 'Список товаров',
                      onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const AdminProductsPage()),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _AdminTile(
                      text: 'Список категорий',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminCategoriesPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _AdminTile(text: 'Список обращений'),
                    SizedBox(height: 16),
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

class _AdminTile extends StatelessWidget {
  const _AdminTile({required this.text, this.onTap});
  final String text;
  final VoidCallback? onTap;

  static const orange = Color(0xFFFF5E1C);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10000),
      onTap: onTap, // потом сюда подставишь переходы на экраны
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10000),
          border: Border.all(color: orange, width: 1), // 1px solid #FF5E1C
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            // иконка как у «Заказы» в нижней навигации
            const Icon(Icons.format_list_bulleted, size: 24, color: orange),
            const SizedBox(width: 12),
            // текст по центру по высоте, сверху/снизу по 16
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 1.0,
                    letterSpacing: 0,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}