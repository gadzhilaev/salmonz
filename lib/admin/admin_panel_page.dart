import 'package:flutter/material.dart';
import 'package:salmonz/core/responsive/app_breakpoints.dart';
import 'package:salmonz/core/responsive/app_page_container.dart';
import 'package:salmonz/core/responsive/responsive_grid.dart';
import 'users/users_list_page.dart';
import 'promotions/promotions_list_page.dart';
import 'orders/admin_orders_page.dart';
import 'categories/admin_categories_page.dart';
import 'products/admin_products_page.dart';
import 'support/admin_support_page.dart';

class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  static const arrowColor = Color(0xFFCDCDCD);
  static const titleDark = Color(0xFF26351E);
  static const orange = Color(0xFFFF5E1C);

  static const double hLogo = 62;
  static const double ls24 = 0.96;

  static const _menuItems = [
    _AdminMenuItem(
      'Список акций',
      PromotionsListPage.new,
      'adminMenuPromotions',
    ),
    _AdminMenuItem('Список пользователей', UsersListPage.new, 'adminMenuUsers'),
    _AdminMenuItem('Список заказов', AdminOrdersPage.new, 'adminMenuOrders'),
    _AdminMenuItem(
      'Список товаров',
      AdminProductsPage.new,
      'adminMenuProducts',
    ),
    _AdminMenuItem(
      'Список категорий',
      AdminCategoriesPage.new,
      'adminMenuCategories',
    ),
    _AdminMenuItem('Обращения', AdminSupportPage.new, 'adminMenuSupport'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = AppBreakpoints.typeScale(width);
    final tileH = AppBreakpoints.controlHeight(width);
    final isCompact = AppBreakpoints.ofWidth(width) == AppBreakpoint.compact;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: AppPageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: hLogo + 26,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      left: 0,
                      top: 26,
                      child: SizedBox(
                        width: tileH,
                        height: tileH,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          splashRadius: 20,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: arrowColor,
                          ),
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
              const SizedBox(height: 24),
              Semantics(
                identifier: 'adminPanelTitle',
                label: 'АДМИН ПАНЕЛЬ',
                child: Text(
                  key: const Key('adminPanelTitle'),
                  'АДМИН ПАНЕЛЬ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w900,
                    fontSize: 24 * scale,
                    height: 1.0,
                    letterSpacing: ls24,
                    color: titleDark,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: isCompact
                    ? ListView(
                        children: [
                          for (final item in _menuItems) ...[
                            _AdminTile(
                              text: item.label,
                              height: tileH,
                              semanticsKey: item.keyId,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => item.builder(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          const SizedBox(height: 16),
                        ],
                      )
                    : ListView(
                        children: [
                          ResponsiveGrid(
                            itemCount: _menuItems.length,
                            minCardWidth: 260,
                            maxColumns: 2,
                            itemHeight: tileH + 8,
                            itemBuilder: (context, index, tileW) {
                              final item = _menuItems[index];
                              return _AdminTile(
                                text: item.label,
                                height: tileH,
                                semanticsKey: item.keyId,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => item.builder(),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
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

class _AdminMenuItem {
  const _AdminMenuItem(this.label, this.builder, this.keyId);
  final String label;
  final Widget Function() builder;
  final String keyId;
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({
    required this.text,
    required this.height,
    required this.semanticsKey,
    this.onTap,
  });
  final String text;
  final double height;
  final String semanticsKey;
  final VoidCallback? onTap;

  static const orange = Color(0xFFFF5E1C);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: semanticsKey,
      button: true,
      label: text,
      child: InkWell(
        key: Key(semanticsKey),
        borderRadius: BorderRadius.circular(10000),
        onTap: onTap,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10000),
            border: Border.all(color: orange, width: 1),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.format_list_bulleted, size: 24, color: orange),
              const SizedBox(width: 12),
              Expanded(
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
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
