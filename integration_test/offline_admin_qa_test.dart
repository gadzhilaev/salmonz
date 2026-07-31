/// Admin list screens offline + retry.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:salmonz/main.dart' as app;
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

Future<void> _login(WidgetTester tester) async {
  await _logout(tester);
  await tester.enterText(
    find.byKey(const Key('loginEmail')),
    'admin@example.com',
  );
  await tester.enterText(
    find.byKey(const Key('loginPassword')),
    'ChangeMeAdmin123!',
  );
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

Future<void> _tapRetry(WidgetTester tester) async {
  final retry = find.text('ПОВТОРИТЬ');
  if (retry.evaluate().isEmpty) return;
  await tester.tap(retry.first);
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (find.text('ПОВТОРИТЬ').evaluate().isEmpty) break;
  }
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin offline retry', (tester) async {
    await _pump(tester);
    await _login(tester);
    await tester.tap(find.byKey(const Key('navProfile')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    final adminEntry = find.byKey(const Key('adminPanelEntry'));
    await tester.ensureVisible(adminEntry);
    await tester.pumpAndSettle();
    await tester.tap(adminEntry, warnIfMissed: false);
    // Fallback: tap by label if key hit-test missed
    if (find.byKey(const Key('adminPanelTitle')).evaluate().isEmpty) {
      final label = find.text('Админ панель');
      if (label.evaluate().isNotEmpty) {
        await tester.ensureVisible(label);
        await tester.tap(label);
      }
    }
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byKey(const Key('adminPanelTitle')), findsOneWidget);
    await _shot(tester, 'offline_admin_panel');

    // ignore: avoid_print
    print('QA_MARKER_STOP_BACKEND');
    for (var i = 0; i < 18; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    Future<void> openOffline(String label, String shot) async {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await _waitForError(tester);
      _assertFriendlyError();
      await _shot(tester, shot);
      await _pop(tester);
    }

    await openOffline('Список категорий', 'offline_admin_categories');
    await openOffline('Список товаров', 'offline_admin_products');
    await openOffline('Список акций', 'offline_admin_promotions');
    await openOffline('Список заказов', 'offline_admin_orders');
    await openOffline('Список пользователей', 'offline_admin_users');
    await openOffline('Обращения', 'offline_admin_support');

    // ignore: avoid_print
    print('QA_MARKER_START_BACKEND');
    for (var i = 0; i < 22; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    Future<void> openRetry(String label, String shot) async {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await _tapRetry(tester);
      if (find.byType(AppErrorView).evaluate().isNotEmpty) {
        await _tapRetry(tester);
      }
      expect(find.byType(AppErrorView), findsNothing);
      await _shot(tester, shot);
      await _pop(tester);
    }

    await openRetry('Список категорий', 'retry_admin_categories');
    await openRetry('Список товаров', 'retry_admin_products');
    await openRetry('Список акций', 'retry_admin_promotions');
    await openRetry('Список заказов', 'retry_admin_orders');
    await openRetry('Список пользователей', 'retry_admin_users');
    await openRetry('Обращения', 'retry_admin_support');
  }, timeout: const Timeout(Duration(minutes: 12)));
}
