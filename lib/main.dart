import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/splash_gate.dart';
import 'core/config/app_config.dart';
import 'core/di/app_services.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/cart/presentation/cubit/cart_cubit.dart';

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
  AppServices.init(config: config);

  final themeController = ThemeController();
  // Do NOT call AuthCubit.restore() here — SplashGate owns a single restore.
  // Parallel refresh with the same token triggers server-side reuse detection
  // and revokes the whole session (looks like "logout after backend restart").
  final authCubit = AuthCubit();
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
