/// Admin list screens offline + retry (per-menu backend toggle via markers).
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
}

Future<void> _logout(WidgetTester tester) async {
  if (find.byKey(const Key('loginSubmit')).evaluate().isNotEmpty) return;
  if (find.byKey(const Key('navProfile')).evaluate().isEmpty) return;
  await tester.tap(find.byKey(const Key('navProfile')));
  await tester.pump(const Duration(seconds: 2));
  final logout = find.byKey(const Key('logoutButton'));
  if (logout.evaluate().isEmpty) return;
  await tester.ensureVisible(logout);
  await tester.tap(logout);
  await tester.pump(const Duration(seconds: 1));
  final confirm = find.text('ВЫЙТИ');
  if (confirm.evaluate().isNotEmpty) {
    await tester.tap(confirm.last);
    for (var i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byKey(const Key('loginSubmit')).evaluate().isNotEmpty) break;
    }
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
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.byKey(const Key('loginSubmit')));
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (find.byKey(const Key('navHome')).evaluate().isNotEmpty) break;
  }
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 400));
  // ignore: avoid_print
  print('QA_SHOT:$name');
  await tester.pump(const Duration(seconds: 2));
}

bool _hasFriendlyError() {
  return find.byKey(const Key('appErrorView')).evaluate().isNotEmpty ||
      find.byKey(const Key('errorRetryButton')).evaluate().isNotEmpty ||
      find.byType(AppErrorView).evaluate().isNotEmpty ||
      find.text('ПОВТОРИТЬ').evaluate().isNotEmpty;
}

Future<void> _waitForError(WidgetTester tester) async {
  for (var i = 0; i < 120; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (_hasFriendlyError()) return;
  }
}

void _assertFriendlyError() {
  expect(_hasFriendlyError(), isTrue, reason: 'Expected AppErrorView / Retry');
  expect(find.textContaining('DioException'), findsNothing);
  expect(find.textContaining('SocketException'), findsNothing);
}

Future<void> _backToAdmin(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    if (find.byKey(const Key('adminPanelTitle')).evaluate().isNotEmpty) {
      return;
    }
    final back = find.byIcon(Icons.arrow_back_ios_new);
    if (back.evaluate().isNotEmpty) {
      await tester.tap(back.first, warnIfMissed: false);
    } else {
      await tester.binding.handlePopRoute();
    }
    await tester.pump(const Duration(milliseconds: 400));
  }
  expect(find.byKey(const Key('adminPanelTitle')), findsOneWidget);
}

Future<void> _openMenu(WidgetTester tester, Key key, String label) async {
  await _backToAdmin(tester);
  final byKey = find.byKey(key);
  final target = byKey.evaluate().isNotEmpty ? byKey : find.text(label);
  expect(target, findsWidgets, reason: 'menu $label');
  await tester.ensureVisible(target.first);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(target.first, warnIfMissed: false);
  for (var i = 0; i < 24; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (find.byKey(const Key('adminPanelTitle')).evaluate().isEmpty) {
      return;
    }
  }
  final byText = find.text(label);
  if (byText.evaluate().isNotEmpty) {
    await tester.ensureVisible(byText.first);
    await tester.tap(byText.first, warnIfMissed: false);
    for (var i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byKey(const Key('adminPanelTitle')).evaluate().isEmpty) {
        return;
      }
    }
  }
  expect(
    find.byKey(const Key('adminPanelTitle')),
    findsNothing,
    reason: 'Failed to open admin menu $label',
  );
}

Future<void> _tapRetry(WidgetTester tester) async {
  final retry = find.byKey(const Key('errorRetryButton')).evaluate().isNotEmpty
      ? find.byKey(const Key('errorRetryButton'))
      : find.text('ПОВТОРИТЬ');
  if (retry.evaluate().isEmpty) return;
  await tester.tap(retry.first, warnIfMissed: false);
  for (var i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (!_hasFriendlyError()) break;
  }
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _waitBackendToggle(WidgetTester tester, int seconds) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin offline retry', (tester) async {
    await _pump(tester);
    await _login(tester);
    await tester.tap(find.byKey(const Key('navProfile')));
    await tester.pump(const Duration(seconds: 2));
    final adminEntry = find.byKey(const Key('adminPanelEntry'));
    await tester.ensureVisible(adminEntry);
    await tester.tap(adminEntry, warnIfMissed: false);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byKey(const Key('adminPanelTitle')).evaluate().isNotEmpty) break;
    }
    if (find.byKey(const Key('adminPanelTitle')).evaluate().isEmpty) {
      final label = find.text('Админ панель');
      if (label.evaluate().isNotEmpty) {
        await tester.tap(label, warnIfMissed: false);
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 250));
          if (find.byKey(const Key('adminPanelTitle')).evaluate().isNotEmpty) {
            break;
          }
        }
      }
    }
    expect(find.byKey(const Key('adminPanelTitle')), findsOneWidget);
    await _shot(tester, 'offline_admin_panel');

    const menus = <(Key, String, String, String)>[
      (
        Key('adminMenuCategories'),
        'Список категорий',
        'offline_admin_categories',
        'retry_admin_categories',
      ),
      (
        Key('adminMenuProducts'),
        'Список товаров',
        'offline_admin_products',
        'retry_admin_products',
      ),
      (
        Key('adminMenuPromotions'),
        'Список акций',
        'offline_admin_promotions',
        'retry_admin_promotions',
      ),
      (
        Key('adminMenuOrders'),
        'Список заказов',
        'offline_admin_orders',
        'retry_admin_orders',
      ),
      (
        Key('adminMenuUsers'),
        'Список пользователей',
        'offline_admin_users',
        'retry_admin_users',
      ),
      (
        Key('adminMenuSupport'),
        'Обращения',
        'offline_admin_support',
        'retry_admin_support',
      ),
    ];

    for (final m in menus) {
      // ignore: avoid_print
      print('QA_MARKER_STOP_BACKEND');
      await _waitBackendToggle(tester, 10);

      await _openMenu(tester, m.$1, m.$2);
      await _waitForError(tester);
      await _shot(tester, m.$3);
      _assertFriendlyError();

      // ignore: avoid_print
      print('QA_MARKER_START_BACKEND');
      await _waitBackendToggle(tester, 18);

      await _tapRetry(tester);
      expect(
        _hasFriendlyError(),
        isFalse,
        reason: 'Retry should clear error for ${m.$2}',
      );
      expect(find.textContaining('DioException'), findsNothing);
      await _shot(tester, m.$4);
      await _backToAdmin(tester);
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}
