import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/login.dart' hide supa;
import 'core/config/app_config.dart';
import 'core/supabase/supa.dart';
import 'nav_bar/main_screen.dart' hide supa;
import 'widgets/cart.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();

  await Supabase.initialize(
    url: config.supabaseUrl,
    anonKey: config.supabasePublishableKey,
  );

  await Cart.instance.load();

  runApp(MyApp(isDemo: config.isDemo));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.isDemo = true});

  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final session = supa.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: session != null ? const SuccessPage() : const Login(),
    );
  }
}
