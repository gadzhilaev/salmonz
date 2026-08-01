/// One admin menu offline + Retry. Pass --dart-define=ADMIN_MENU=products
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:salmonz/main.dart' as app;
import 'package:salmonz/widgets/app_error_view.dart';

const _menu = String.fromEnvironment('ADMIN_MENU', defaultValue: 'categories');

(Key, String, String, String) _target() {
  switch (_menu) {
    case 'products':
      return (
        const Key('adminMenuProducts'),
        'Список товаров',
        'offline_admin_products',
        'retry_admin_products',
      );
    case 'promotions':
      return (
        const Key('adminMenuPromotions'),
        'Список акций',
        'offline_admin_promotions',
        'retry_admin_promotions',
      );
    case 'orders':
      return (
        const Key('adminMenuOrders'),
        'Список заказов',
        'offline_admin_orders',
        'retry_admin_orders',
      );
    case 'users':
      return (
        const Key('adminMenuUsers'),
        'Список пользователей',
        'offline_admin_users',
        'retry_admin_users',
      );
    case 'support':
      return (
        const Key('adminMenuSupport'),
        'Обращения',
        'offline_admin_support',
        'retry_admin_support',
      );
    case 'categories':
    default:
      return (
        const Key('adminMenuCategories'),
        'Список категорий',
        'offline_admin_categories',
        'retry_admin_categories',
      );
  }
}

Future<void> _pumpApp(WidgetTester tester) async {
  await app.main();
  for (var i = 0; i < 24; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _loginAdmin(WidgetTester tester) async {
  if (find.byKey(const Key('loginSubmit')).evaluate().isEmpty) {
    if (find.byKey(const Key('navProfile')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('navProfile')));
      await tester.pump(const Duration(seconds: 2));
      final logout = find.byKey(const Key('logoutButton'));
      if (logout.evaluate().isNotEmpty) {
        await tester.ensureVisible(logout);
        await tester.tap(logout);
        await tester.pump(const Duration(seconds: 1));
        final confirm = find.text('ВЫЙТИ');
        if (confirm.evaluate().isNotEmpty) {
          await tester.tap(confirm.last);
          for (var i = 0; i < 24; i++) {
            await tester.pump(const Duration(milliseconds: 250));
            if (find.byKey(const Key('loginSubmit')).evaluate().isNotEmpty) {
              break;
            }
          }
        }
      }
    }
  }
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
}

Future<void> _openAdmin(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('navProfile')));
  await tester.pump(const Duration(seconds: 2));
  final entry = find.byKey(const Key('adminPanelEntry'));
  await tester.ensureVisible(entry);
  await tester.tap(entry, warnIfMissed: false);
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
}

bool _hasError() =>
    find.byKey(const Key('appErrorView')).evaluate().isNotEmpty ||
    find.byKey(const Key('errorRetryButton')).evaluate().isNotEmpty ||
    find.byType(AppErrorView).evaluate().isNotEmpty ||
    find.text('ПОВТОРИТЬ').evaluate().isNotEmpty;

Future<void> _shot(String name) async {
  // ignore: avoid_print
  print('QA_SHOT:$name');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin one menu offline retry ($_menu)', (tester) async {
    final t = _target();
    await _pumpApp(tester);
    await _loginAdmin(tester);
    await _openAdmin(tester);
    await _shot('offline_admin_panel');
    await tester.pump(const Duration(seconds: 2));

    // ignore: avoid_print
    print('QA_MARKER_STOP_BACKEND');
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    final byKey = find.byKey(t.$1);
    final target = byKey.evaluate().isNotEmpty ? byKey : find.text(t.$2);
    await tester.ensureVisible(target.first);
    await tester.tap(target.first, warnIfMissed: false);
    for (var i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byKey(const Key('adminPanelTitle')).evaluate().isEmpty) break;
    }
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (_hasError()) break;
    }
    await _shot(t.$3);
    await tester.pump(const Duration(seconds: 2));
    expect(_hasError(), isTrue, reason: 'offline ${t.$2}');
    expect(find.textContaining('DioException'), findsNothing);

    // ignore: avoid_print
    print('QA_MARKER_START_BACKEND');
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    final retry = find.byKey(const Key('errorRetryButton')).evaluate().isNotEmpty
        ? find.byKey(const Key('errorRetryButton'))
        : find.text('ПОВТОРИТЬ');
    expect(retry, findsWidgets);
    await tester.tap(retry.first, warnIfMissed: false);
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (!_hasError()) break;
    }
    expect(_hasError(), isFalse, reason: 'retry ${t.$2}');
    await _shot(t.$4);
    await tester.pump(const Duration(seconds: 2));
  }, timeout: const Timeout(Duration(minutes: 4)));
}
