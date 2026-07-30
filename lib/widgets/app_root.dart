import 'package:flutter/material.dart';

import '../nav_bar/basket.dart';
import '../nav_bar/main_screen.dart';
import '../nav_bar/orders.dart';
import '../nav_bar/profile.dart';
import 'app_nav_bar.dart';
import 'app_shell.dart';

/// Logged-in root with adaptive bottom bar / NavigationRail.
class AppRoot extends StatelessWidget {
  const AppRoot({super.key, this.initialTab = AppTab.home});

  final AppTab initialTab;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      initialTab: initialTab,
      pages: const [
        SuccessPage(embedded: true),
        OrdersPage(embedded: true),
        BasketPage(embedded: true),
        ProfilePage(embedded: true),
      ],
    );
  }
}
