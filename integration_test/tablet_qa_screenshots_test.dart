/// Visual QA screenshots against live local API (iPad / iPhone).
///
/// ```bash
/// flutter test integration_test/tablet_qa_screenshots_test.dart \
///   -d <device> --dart-define-from-file=config/local.json
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/main.dart' as app;

Future<void> _pump(WidgetTester tester) async {
  await app.main();
  for (var i = 0; i < 24; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Future<void> _logoutIfNeeded(WidgetTester tester) async {
  if (find.byKey(const Key('loginSubmit')).evaluate().isNotEmpty) return;
  final profile = find.byKey(const Key('navProfile'));
  if (profile.evaluate().isEmpty) return;
  await tester.tap(profile);
  await tester.pumpAndSettle(const Duration(seconds: 2));
  final logout = find.byKey(const Key('logoutButton'));
  if (logout.evaluate().isEmpty) return;
  await tester.ensureVisible(logout);
  await tester.tap(logout);
  await tester.pumpAndSettle();
  final confirm = find.text('ВЫЙТИ');
  if (confirm.evaluate().isNotEmpty) {
    await tester.tap(confirm.last);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}

Future<void> _login(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await _logoutIfNeeded(tester);
  await tester.enterText(find.byKey(const Key('loginEmail')), email);
  await tester.enterText(find.byKey(const Key('loginPassword')), password);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('loginSubmit')));
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (find.byKey(const Key('navHome')).evaluate().isNotEmpty ||
        find.byKey(const Key('homeCategory')).evaluate().isNotEmpty) {
      break;
    }
  }
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tablet/phone visual smoke + screenshots', (tester) async {
    await _pump(tester);
    expect(AppServices.instance.config.apiBaseUrl, contains('3000'));

    await _logoutIfNeeded(tester);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byKey(const Key('loginSubmit')), findsOneWidget);

    // Screenshots are collected by integration_test driver (flutter drive).
    await binding.takeScreenshot('qa_login');

    await _login(
      tester,
      email: 'demo@example.com',
      password: 'ChangeMeDemo123!',
    );
    expect(
      find.byKey(const Key('homeCategory')).evaluate().isNotEmpty ||
          find.byKey(const Key('navHome')).evaluate().isNotEmpty,
      isTrue,
    );
    await binding.takeScreenshot('qa_home_light');

    // Dark theme via profile cycle if available.
    final profile = find.byKey(const Key('navProfile'));
    if (profile.evaluate().isNotEmpty) {
      await tester.tap(profile);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await binding.takeScreenshot('qa_profile_light');

      final themeBtn = find.byKey(const Key('themeToggle'));
      if (themeBtn.evaluate().isNotEmpty) {
        await tester.ensureVisible(themeBtn);
        // Cycle until dark label appears (system→light→dark).
        for (var i = 0; i < 3; i++) {
          await tester.tap(themeBtn);
          await tester.pumpAndSettle();
          if (find.textContaining('Тёмн').evaluate().isNotEmpty) break;
        }
        await binding.takeScreenshot('qa_profile_dark');
      }
    }

    final home = find.byKey(const Key('navHome'));
    if (home.evaluate().isNotEmpty) {
      await tester.tap(home);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    final cat = find.byKey(const Key('homeCategory'));
    if (cat.evaluate().isNotEmpty) {
      await tester.tap(cat.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await binding.takeScreenshot('qa_category_grid');
      final back = find.byIcon(Icons.arrow_back_ios_new);
      if (back.evaluate().isNotEmpty) {
        await tester.tap(back.first);
        await tester.pumpAndSettle();
      }
    }

    final basket = find.byKey(const Key('navBasket'));
    if (basket.evaluate().isNotEmpty) {
      await tester.tap(basket);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await binding.takeScreenshot('qa_cart');
    }

    await _logoutIfNeeded(tester);
    await _login(
      tester,
      email: 'admin@example.com',
      password: 'ChangeMeAdmin123!',
    );
    final adminProfile = find.byKey(const Key('navProfile'));
    await tester.tap(adminProfile);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    final adminEntry = find.byKey(const Key('adminPanelEntry'));
    if (adminEntry.evaluate().isNotEmpty) {
      await tester.ensureVisible(adminEntry);
      await tester.tap(adminEntry);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      for (var i = 0; i < 20; i++) {
        if (find.textContaining('АДМИН').evaluate().isNotEmpty) break;
        await tester.pump(const Duration(milliseconds: 250));
      }
      await binding.takeScreenshot('qa_admin_dashboard');
    }
  });
}
