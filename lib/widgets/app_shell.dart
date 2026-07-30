import 'package:flutter/material.dart';

import '../core/responsive/app_breakpoints.dart';
import 'app_nav_bar.dart';

/// Primary app chrome: bottom bar on phones, NavigationRail on tablets.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.initialTab = AppTab.home,
    required this.pages,
  });

  final AppTab initialTab;

  /// Exactly four pages: home, orders, basket, profile — without bottom bars.
  final List<Widget> pages;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late AppTab _tab;

  static const Color orange = Color(0xFFFF5E1C);

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    assert(widget.pages.length == 4, 'AppShell expects 4 tab pages');
  }

  int get _index => switch (_tab) {
    AppTab.home => 0,
    AppTab.orders => 1,
    AppTab.basket => 2,
    AppTab.profile => 3,
  };

  void _select(AppTab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final useRail = AppBreakpoints.useNavigationRailForSize(size);
    final iconSize = AppBreakpoints.iconSize(width);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark
        ? Theme.of(context).colorScheme.onSurface
        : const Color(0xFF282828);

    final body = IndexedStack(index: _index, children: widget.pages);

    if (useRail) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (i) {
                  _select(switch (i) {
                    0 => AppTab.home,
                    1 => AppTab.orders,
                    2 => AppTab.basket,
                    _ => AppTab.profile,
                  });
                },
                labelType: NavigationRailLabelType.all,
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedIconTheme: IconThemeData(color: orange, size: iconSize),
                unselectedIconTheme: IconThemeData(
                  color: muted,
                  size: iconSize,
                ),
                selectedLabelTextStyle: TextStyle(
                  color: orange,
                  fontWeight: FontWeight.w700,
                  fontSize: 12 * AppBreakpoints.typeScale(width),
                ),
                unselectedLabelTextStyle: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12 * AppBreakpoints.typeScale(width),
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined, key: Key('navHome')),
                    label: Text('Главная'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(
                      Icons.format_list_bulleted,
                      key: Key('navOrders'),
                    ),
                    label: Text('Заказы'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(
                      Icons.shopping_cart_outlined,
                      key: Key('navBasket'),
                    ),
                    label: Text('Корзина'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(
                      Icons.account_circle_outlined,
                      key: Key('navProfile'),
                    ),
                    label: Text('Профиль'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: AppNavBar(current: _tab, onTap: _select),
    );
  }
}
