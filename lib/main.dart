import 'package:flutter/material.dart';

import 'auth/login.dart';
import 'core/config/app_config.dart';
import 'core/di/app_services.dart';
import 'core/theme/app_theme.dart';
import 'nav_bar/main_screen.dart';
import 'widgets/cart.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  AppServices.init(config: config);

  await Cart.instance.load();

  final user = await AppServices.instance.auth.restoreSession();

  runApp(MyApp(isLoggedIn: user != null, isDemo: config.isDemo));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.isLoggedIn = false, this.isDemo = true});

  final bool isLoggedIn;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: isLoggedIn ? const SuccessPage() : const Login(),
    );
  }
}
