import 'package:flutter/material.dart';

import 'auth/login.dart';
import 'core/config/app_config.dart';
import 'core/di/app_services.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'nav_bar/main_screen.dart';
import 'widgets/cart.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  AppServices.init(config: config);

  await Cart.instance.load();

  final themeController = ThemeController();
  await themeController.load();

  final user = await AppServices.instance.auth.restoreSession();

  runApp(MyApp(
    isLoggedIn: user != null,
    isDemo: config.isDemo,
    themeController: themeController,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.isLoggedIn = false,
    this.isDemo = true,
    required this.themeController,
  });

  final bool isLoggedIn;
  final bool isDemo;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: themeController,
      child: AnimatedBuilder(
        animation: themeController,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeController.mode,
            home: isLoggedIn ? const SuccessPage() : const Login(),
          );
        },
      ),
    );
  }
}
