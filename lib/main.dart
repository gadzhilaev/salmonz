import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/splash_gate.dart';
import 'auth/login.dart';
import 'core/config/app_config.dart';
import 'core/di/app_services.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/cart/presentation/cubit/cart_cubit.dart';
import 'widgets/app_notice.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

var _handlingSessionExpiry = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Match native launch / Flutter splash brand color while engines boot.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.orange,
    ),
  );

  final config = AppConfig.fromEnvironment();
  late final AuthCubit authCubit;

  AppServices.init(
    config: config,
    onSessionExpired: () {
      if (_handlingSessionExpiry) return;
      _handlingSessionExpiry = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          authCubit.emitUnauthenticated();
          final nav = appNavigatorKey.currentState;
          final ctx = appNavigatorKey.currentContext;
          if (ctx != null) AppNotice.clear(ctx);
          nav?.pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const Login()),
            (_) => false,
          );
        } finally {
          _handlingSessionExpiry = false;
        }
      });
    },
  );

  final themeController = ThemeController();
  // Do NOT call AuthCubit.restore() here — SplashGate owns a single restore.
  authCubit = AuthCubit();
  final cartCubit = CartCubit()..hydrate();

  runApp(
    MyApp(
      themeController: themeController,
      isDemo: config.isDemo,
      authCubit: authCubit,
      cartCubit: cartCubit,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.isDemo = true,
    required this.themeController,
    required this.authCubit,
    required this.cartCubit,
  });

  final bool isDemo;
  final ThemeController themeController;
  final AuthCubit authCubit;
  final CartCubit cartCubit;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<CartCubit>.value(value: cartCubit),
      ],
      child: ThemeScope(
        controller: themeController,
        child: AnimatedBuilder(
          animation: themeController,
          builder: (context, _) {
            return MaterialApp(
              navigatorKey: appNavigatorKey,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeController.mode,
              home: SplashGate(themeController: themeController),
            );
          },
        ),
      ),
    );
  }
}
