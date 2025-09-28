import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/cart.dart';
import 'auth/login.dart';
import 'nav_bar/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vwerkkbccwosrnkozgza.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ3ZXJra2JjY3dvc3Jua296Z3phIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc1MzMyMjUsImV4cCI6MjA3MzEwOTIyNX0.m8KJzRtS00JAR_nZJAVOAkt-nwiBrOrQV3Qa5G2osnY',
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