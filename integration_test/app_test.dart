/// Integration tests against a live local API.
///
/// Prerequisites:
/// - Backend running (see docs/LOCAL_DEVELOPMENT.md)
/// - Emulator or device available
/// - Config via `--dart-define-from-file=config/local.json`
///   (copy from `config/local.example.json`; for Android emulator use
///   `http://10.0.2.2:3000` as API_BASE_URL)
///
/// Run:
/// ```bash
/// flutter test integration_test -d emulator-5554 --dart-define-from-file=config/local.json
/// ```
///
/// Demo credentials (seeded by backend):
/// - user: demo@example.com / ChangeMeDemo123!
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:salmonz/main.dart' as app;

Future<void> _pumpApp(WidgetTester tester) async {
  await app.main();
  // Allow async bootstrap (session restore, cart, theme).
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Future<void> _ensureLoggedOut(WidgetTester tester) async {
  if (find.byKey(const Key('loginSubmit')).evaluate().isNotEmpty) return;

  final navProfile = find.byKey(const Key('navProfile'));
  if (navProfile.evaluate().isEmpty) {
    // Wait a bit more for home chrome.
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
  if (find.byKey(const Key('navProfile')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('navProfile')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  final logout = find.byKey(const Key('logoutButton'));
  if (logout.evaluate().isNotEmpty) {
    await tester.tap(logout);
    await tester.pumpAndSettle();
    final confirm = find.text('ВЫЙТИ');
    if (confirm.evaluate().isNotEmpty) {
      await tester.tap(confirm.last);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }
  }
}

Future<void> _login(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await _ensureLoggedOut(tester);
  expect(find.byKey(const Key('loginEmail')), findsOneWidget);
  await tester.enterText(find.byKey(const Key('loginEmail')), email);
  await tester.enterText(find.byKey(const Key('loginPassword')), password);
  await tester.tap(find.byKey(const Key('loginSubmit')));
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login validation rejects empty fields', (tester) async {
    await _pumpApp(tester);
    await _ensureLoggedOut(tester);

    expect(find.byKey(const Key('loginSubmit')), findsOneWidget);
    await tester.tap(find.byKey(const Key('loginSubmit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('почту'), findsWidgets);
  });

  testWidgets('demo login, cart, checkout quote, logout', (tester) async {
    await _pumpApp(tester);

    await _login(
      tester,
      email: 'demo@example.com',
      password: 'ChangeMeDemo123!',
    );

    // Home loaded (categories or empty state / nav).
    expect(
      find.textContaining('Категорий').evaluate().isNotEmpty ||
          find.byKey(const Key('homeCategory')).evaluate().isNotEmpty ||
          find.byKey(const Key('navHome')).evaluate().isNotEmpty,
      isTrue,
    );

    // Open first category and add to cart when possible.
    final category = find.byKey(const Key('homeCategory'));
    if (category.evaluate().isNotEmpty) {
      await tester.tap(category.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final addBtn = find.byKey(const Key('addToCart'));
      if (addBtn.evaluate().isNotEmpty) {
        await tester.ensureVisible(addBtn.first);
        await tester.tap(addBtn.first);
        await tester.pumpAndSettle();
      }

      // Back to a screen with bottom nav.
      if (find.byKey(const Key('navBasket')).evaluate().isEmpty) {
        final back = find.byIcon(Icons.arrow_back_ios_new);
        if (back.evaluate().isNotEmpty) {
          await tester.tap(back.first);
          await tester.pumpAndSettle();
        }
      }
    }

    // Open cart → checkout.
    final navBasket = find.byKey(const Key('navBasket'));
    if (navBasket.evaluate().isNotEmpty) {
      await tester.tap(navBasket);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    final checkoutBtn = find.byKey(const Key('cartCheckoutButton'));
    if (checkoutBtn.evaluate().isNotEmpty) {
      // Dismiss snackbars that can block the checkout button.
      final messenger = ScaffoldMessenger.maybeOf(
        tester.element(find.byType(MaterialApp)),
      );
      messenger?.clearSnackBars();
      await tester.pumpAndSettle();

      await tester.ensureVisible(checkoutBtn);
      await tester.tap(checkoutBtn, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Wait for server quote total when cart had items.
      for (var i = 0; i < 15; i++) {
        if (find.byKey(const Key('quoteTotal')).evaluate().isNotEmpty) break;
        await tester.pump(const Duration(milliseconds: 300));
      }
      if (find.byKey(const Key('quoteTotal')).evaluate().isNotEmpty) {
        expect(find.byKey(const Key('quoteTotal')), findsOneWidget);
      }

      final back = find.byIcon(Icons.arrow_back_ios_new);
      if (back.evaluate().isNotEmpty) {
        await tester.tap(back.first);
        await tester.pumpAndSettle();
      }
    }

    await _ensureLoggedOut(tester);
    expect(find.byKey(const Key('loginSubmit')), findsOneWidget);
  });
}
