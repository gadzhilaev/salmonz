/// Focused offline/retry for home, orders, cart quote, profile (+ retries).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/main.dart' as app;
import 'package:salmonz/products_pages/products.dart';
import 'package:salmonz/widgets/app_error_view.dart';

Future<void> _pump(WidgetTester tester) async {
  await app.main();
  for (var i = 0; i < 24; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Future<void> _logout(WidgetTester tester) async {
  if (find.byKey(const Key('loginSubmit')).evaluate().isNotEmpty) return;
  if (find.byKey(const Key('navProfile')).evaluate().isEmpty) return;
  await tester.tap(find.byKey(const Key('navProfile')));
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

Future<void> _login(WidgetTester tester, String email, String password) async {
  await _logout(tester);
  await tester.enterText(find.byKey(const Key('loginEmail')), email);
  await tester.enterText(find.byKey(const Key('loginPassword')), password);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('loginSubmit')));
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (find.byKey(const Key('navHome')).evaluate().isNotEmpty) break;
  }
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 400));
  // ignore: avoid_print
  print('QA_SHOT:$name');
  await tester.pump(const Duration(seconds: 2));
}

Future<void> _waitForError(WidgetTester tester) async {
  for (var i = 0; i < 120; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (find.byType(AppErrorView).evaluate().isNotEmpty ||
        find.text('ПОВТОРИТЬ').evaluate().isNotEmpty) {
      return;
    }
  }
}

void _assertFriendlyError() {
  expect(
    find.byType(AppErrorView).evaluate().isNotEmpty ||
        find.text('ПОВТОРИТЬ').evaluate().isNotEmpty,
    isTrue,
  );
  expect(find.textContaining('DioException'), findsNothing);
  expect(find.textContaining('SocketException'), findsNothing);
  expect(
    find.textContaining('Нет соединения').evaluate().isNotEmpty ||
        find.textContaining('сервер').evaluate().isNotEmpty ||
        find.textContaining('ожидания').evaluate().isNotEmpty,
    isTrue,
  );
}

Future<void> _pull(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable).first, const Offset(0, 420));
  await tester.pump(const Duration(milliseconds: 400));
  await _waitForError(tester);
}

Future<void> _tapRetry(WidgetTester tester) async {
  final retry = find.text('ПОВТОРИТЬ');
  expect(retry, findsWidgets);
  await tester.tap(retry.first);
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (find.text('ПОВТОРИТЬ').evaluate().isEmpty) break;
  }
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Future<void> _pop(WidgetTester tester) async {
  final back = find.byIcon(Icons.arrow_back_ios_new);
  if (back.evaluate().isNotEmpty) {
    await tester.tap(back.first);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    return;
  }
  final err = find.byType(AppErrorView);
  if (err.evaluate().isNotEmpty) {
    final nav = Navigator.of(tester.element(err.first));
    if (nav.canPop()) nav.pop();
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tabs offline retry', (tester) async {
    await _pump(tester);
    await _login(tester, 'demo@example.com', 'ChangeMeDemo123!');

    // Seed cart with a real product before going offline
    await tester.tap(find.byKey(const Key('navHome')));
    await tester.pumpAndSettle();
    final cats = await AppServices.instance.catalog.getCategories();
    final rolls = cats.firstWhere(
      (c) => c.name.toLowerCase().contains('ролл'),
      orElse: () => cats.first,
    );
    Navigator.of(tester.element(find.byKey(const Key('navHome')))).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductsPage(title: rolls.name, categoryId: rolls.id),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));
    final add = find.text('ДОБАВИТЬ В КОРЗИНУ');
    if (add.evaluate().isNotEmpty) {
      await tester.tap(add.first);
      await tester.pumpAndSettle();
    }
    await _pop(tester);

    // ignore: avoid_print
    print('QA_MARKER_STOP_BACKEND');
    for (var i = 0; i < 18; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    await tester.tap(find.byKey(const Key('navHome')));
    await tester.pumpAndSettle();
    await _pull(tester);
    _assertFriendlyError();
    await _shot(tester, 'offline_home');
    await _shot(tester, 'offline_categories');

    await tester.tap(find.byKey(const Key('navOrders')));
    await tester.pumpAndSettle();
    await _pull(tester);
    _assertFriendlyError();
    await _shot(tester, 'offline_orders');

    await tester.tap(find.byKey(const Key('navBasket')));
    await tester.pumpAndSettle();
    if (find.text('ОФОРМИТЬ ЗАКАЗ').evaluate().isNotEmpty) {
      await tester.tap(find.text('ОФОРМИТЬ ЗАКАЗ'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await _waitForError(tester);
      if (find.byType(AppErrorView).evaluate().isNotEmpty ||
          find.text('ПОВТОРИТЬ').evaluate().isNotEmpty) {
        _assertFriendlyError();
        await _shot(tester, 'offline_cart_quote');
      } else {
        await _shot(tester, 'offline_cart_quote_missing_error');
      }
      await _pop(tester);
    } else {
      await _shot(tester, 'offline_cart_empty');
    }

    await tester.tap(find.byKey(const Key('navProfile')));
    await tester.pumpAndSettle();
    await _pull(tester);
    _assertFriendlyError();
    await _shot(tester, 'offline_profile');

    // ignore: avoid_print
    print('QA_MARKER_START_BACKEND');
    for (var i = 0; i < 22; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    await tester.tap(find.byKey(const Key('navHome')));
    await tester.pumpAndSettle();
    if (find.text('ПОВТОРИТЬ').evaluate().isNotEmpty) await _tapRetry(tester);
    expect(find.byType(AppErrorView), findsNothing);
    await _shot(tester, 'retry_home');
    await _shot(tester, 'retry_categories');

    await tester.tap(find.byKey(const Key('navOrders')));
    await tester.pumpAndSettle();
    if (find.text('ПОВТОРИТЬ').evaluate().isNotEmpty) await _tapRetry(tester);
    expect(find.byType(AppErrorView), findsNothing);
    await _shot(tester, 'retry_orders');

    await tester.tap(find.byKey(const Key('navProfile')));
    await tester.pumpAndSettle();
    if (find.text('ПОВТОРИТЬ').evaluate().isNotEmpty) await _tapRetry(tester);
    expect(find.byType(AppErrorView), findsNothing);
    await _shot(tester, 'retry_profile');

    await tester.tap(find.byKey(const Key('navBasket')));
    await tester.pumpAndSettle();
    if (find.text('ОФОРМИТЬ ЗАКАЗ').evaluate().isNotEmpty) {
      await tester.tap(find.text('ОФОРМИТЬ ЗАКАЗ'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      if (find.text('ПОВТОРИТЬ').evaluate().isNotEmpty) await _tapRetry(tester);
      await _shot(tester, 'retry_cart_quote');
      await _pop(tester);
    }
  }, timeout: const Timeout(Duration(minutes: 12)));
}
