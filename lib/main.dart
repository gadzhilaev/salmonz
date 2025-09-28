import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/cart.dart';
import 'auth/login.dart';
import 'nav_bar/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vwerkkbccwosrnkozgza.supabase.co',
    anonKey: 'REDACTED_SUPABASE_ANON_JWT',
  );
  // загружаем корзину
  await Cart.instance.load();

  runApp(const MyApp());
}

final supa = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // проверяем, сохранена ли сессия
    final session = supa.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: session != null ? const SuccessPage() : const Login(),
    );
  }
}