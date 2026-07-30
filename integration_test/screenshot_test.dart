/// Captures portfolio screenshots on a live Simulator + local API.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/core/theme/theme_controller.dart';
import 'package:salmonz/main.dart' as app;

Future<void> _pump(WidgetTester tester) async {
  await app.main();
  for (var i = 0; i < 24; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Future<void> _login(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  if (find.byKey(const Key('loginSubmit')).evaluate().isEmpty) {
    final logout = find.byKey(const Key('logoutButton'));
    if (find.byKey(const Key('navProfile')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('navProfile')));
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }
    if (logout.evaluate().isNotEmpty) {
      await tester.ensureVisible(logout);
      await tester.tap(logout);
      await tester.pumpAndSettle();
      final confirm = find.text('ВЫЙТИ');
      if (confirm.evaluate().isNotEmpty) {
        await tester.tap(confirm.last);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
    }
  }

  await tester.tap(find.byKey(const Key('loginEmail')));
  await tester.enterText(find.byKey(const Key('loginEmail')), email);
  await tester.tap(find.byKey(const Key('loginPassword')));
  await tester.enterText(find.byKey(const Key('loginPassword')), password);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('loginSubmit')));
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (find.byKey(const Key('navHome')).evaluate().isNotEmpty) break;
  }
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture screenshots', (tester) async {
    await _pump(tester);
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    await binding.takeScreenshot('01_login');

    await _login(
      tester,
      email: 'demo@example.com',
      password: 'ChangeMeDemo123!',
    );
    await tester.pump();
    await binding.takeScreenshot('02_home_light');

    final category = find.byKey(const Key('homeCategory'));
    if (category.evaluate().isNotEmpty) {
      await tester.tap(category.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await binding.takeScreenshot('03_category');
      final back = find.byIcon(Icons.arrow_back_ios_new);
      if (back.evaluate().isNotEmpty) {
        await tester.tap(back.first);
        await tester.pumpAndSettle();
      }
    }

    await tester.tap(find.byKey(const Key('navProfile')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await binding.takeScreenshot('04_profile_light');

    final theme = find.byKey(const Key('themeToggle'));
    if (theme.evaluate().isNotEmpty) {
      await tester.ensureVisible(theme);
      // Cycle to dark (system -> light -> dark).
      await tester.tap(theme);
      await tester.pumpAndSettle();
      await tester.tap(theme);
      await tester.pumpAndSettle();
      await binding.takeScreenshot('05_profile_dark');
    }

    // Force dark via controller if available.
    final scope = ThemeScope.maybeOf(tester.element(find.byType(MaterialApp)));
    if (scope != null) {
      await scope.setMode(ThemeMode.dark);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('navHome')));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await binding.takeScreenshot('06_home_dark');
    }

    expect(AppServices.instance.config.apiBaseUrl, isNotEmpty);
  });
}
