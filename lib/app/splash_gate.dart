import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/login.dart';
import '../core/di/app_services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/theme_controller.dart';
import '../data/models/models.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../widgets/app_network_image.dart';
import '../widgets/app_notice.dart';
import '../widgets/app_root.dart';
import '../widgets/cart.dart';

/// Cold-start gate. Matches native splash color/logo; no "Загрузка" text.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  static const _minVisible = Duration(milliseconds: 550);
  static const _timeout = Duration(seconds: 6);

  UserModel? _user;
  var _ready = false;
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final started = DateTime.now();

    try {
      await Future.any([_warm(), Future<void>.delayed(_timeout)]);
    } catch (_) {}

    final elapsed = DateTime.now().difference(started);
    if (elapsed < _minVisible) {
      await Future<void>.delayed(_minVisible - elapsed);
    }

    if (mounted) setState(() => _ready = true);
  }

  Future<void> _warm() async {
    await Future.wait([Cart.instance.load(), widget.themeController.load()]);

    try {
      _user = await AppServices.instance.auth.restoreSession();
      if (!mounted) return;
      // Keep AuthCubit in sync without a second refresh call.
      final cubit = context.read<AuthCubit>();
      if (_user != null) {
        cubit.emitAuthenticated(_user!);
      } else {
        cubit.emitUnauthenticated();
        AppNotice.clear(context);
      }
    } catch (_) {
      _user = null;
      if (mounted) {
        context.read<AuthCubit>().emitUnauthenticated();
        AppNotice.clear(context);
      }
    }

    if (!mounted) return;

    // Non-blocking catalog warm: home data + limited image precache.
    try {
      final catalog = AppServices.instance.catalog;
      final cats = await catalog.getCategories();
      final promos = await catalog.getPromotions();
      if (!mounted) return;

      final urls = <String?>[
        ...promos.map((p) => p.imageUrl),
        ...cats.take(8).map((c) => c.imageUrl),
      ];

      // First products of first category — limited.
      if (cats.isNotEmpty) {
        try {
          final page = await catalog.getProducts(
            categoryId: cats.first.id,
            limit: 8,
          );
          urls.addAll(page.data.map((p) => p.imageUrl));
        } catch (_) {}
      }

      if (!mounted) return;
      await AppNetworkImage.precacheUrls(context, urls, limit: 14);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const _SplashView();
    return _user != null ? const AppRoot() : const Login();
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.orange,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Image(
              image: AssetImage('assets/icon/logo_salmonz.png'),
              width: 160,
              height: 124,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 56,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
