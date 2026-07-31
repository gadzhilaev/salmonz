/// Offline / Retry QA with real `docker stop` of the local API.
///
/// Host orchestration (`scripts/offline_qa_run.sh`) watches stdout markers:
/// - `QA_MARKER_STOP_BACKEND` / `QA_MARKER_START_BACKEND`
/// - `QA_SHOT:<name>` → `xcrun simctl io … screenshot docs/screenshots/qa/<name>.png`
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
  await _logout(tester);
  expect(find.byKey(const Key('loginEmail')), findsOneWidget);
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
  expect(find.byKey(const Key('navHome')), findsOneWidget);
}

Future<void> _shot(WidgetTester tester, String name) async {
  // Host orchestrator captures via simctl; settle UI first.
  await tester.pump(const Duration(milliseconds: 400));
  // ignore: avoid_print
  print('QA_SHOT:$name');
  await tester.pump(const Duration(seconds: 2));
}

Future<void> _waitForError(WidgetTester tester) async {
  for (var i = 0; i < 120; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (find.byType(AppErrorView).evaluate().isNotEmpty ||
        find.byKey(const Key('errorRetryButton')).evaluate().isNotEmpty ||
        find.text('ПОВТОРИТЬ').evaluate().isNotEmpty) {
      return;
    }
  }
}

void _assertFriendlyError() {
  final hasError =
      find.byType(AppErrorView).evaluate().isNotEmpty ||
      find.byKey(const Key('errorRetryButton')).evaluate().isNotEmpty ||
      find.text('ПОВТОРИТЬ').evaluate().isNotEmpty;
  expect(hasError, isTrue, reason: 'Expected AppErrorView / Retry');
  expect(find.textContaining('DioException'), findsNothing);
  expect(find.textContaining('SocketException'), findsNothing);
  expect(find.textContaining('Exception:'), findsNothing);
  final hasRu =
      find.textContaining('Нет соединения').evaluate().isNotEmpty ||
      find.textContaining('соединен').evaluate().isNotEmpty ||
      find.textContaining('сервер').evaluate().isNotEmpty ||
      find.textContaining('ошибк').evaluate().isNotEmpty ||
      find.textContaining('ожидания').evaluate().isNotEmpty;
  expect(hasRu, isTrue, reason: 'Expected Russian user-facing error copy');
}

Future<void> _pullToRefresh(WidgetTester tester) async {
  final list = find.byType(Scrollable).first;
  await tester.drag(list, const Offset(0, 400));
  await tester.pump(const Duration(milliseconds: 500));
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (find.byType(AppErrorView).evaluate().isNotEmpty) break;
  }
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _tapRetry(WidgetTester tester) async {
  final retry = find.byKey(const Key('errorRetryButton'));
  expect(retry, findsWidgets);
  await tester.ensureVisible(retry.first);
  await tester.tap(retry.first);
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (find.byKey(const Key('errorRetryButton')).evaluate().isEmpty) break;
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
    if (nav.canPop()) {
      nav.pop();
      await tester.pumpAndSettle(const Duration(seconds: 1));
      return;
    }
  }
  final navFinder = find.byType(Navigator);
  if (navFinder.evaluate().isNotEmpty) {
    final nav = tester.state<NavigatorState>(navFinder.last);
    if (nav.canPop()) {
      nav.pop();
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }
  }
}

Future<void> _openRollsProducts(WidgetTester tester) async {
  final cats = await AppServices.instance.catalog.getCategories();
  final rolls = cats.firstWhere(
    (c) => c.name.toLowerCase().contains('ролл'),
    orElse: () => cats.first,
  );
  final navCtx = tester.element(find.byKey(const Key('navHome')));
  Navigator.of(navCtx).push(
    MaterialPageRoute<void>(
      builder: (_) => ProductsPage(title: rolls.name, categoryId: rolls.id),
    ),
  );
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

Future<void> _waitBackendDown(WidgetTester tester) async {
  // ignore: avoid_print
  print('QA_MARKER_STOP_BACKEND');
  // Host stops docker; fixed wait avoids device HttpClient flakiness.
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

Future<void> _waitBackendUp(WidgetTester tester) async {
  // ignore: avoid_print
  print('QA_MARKER_START_BACKEND');
  for (var i = 0; i < 25; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'USER + ADMIN offline/retry matrix',
    (tester) async {
      await _pump(tester);

      await _login(
        tester,
        email: 'demo@example.com',
        password: 'ChangeMeDemo123!',
      );

      await tester.tap(find.byKey(const Key('navHome')));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await _openRollsProducts(tester);

      final philadelphia = find.textContaining('ФИЛАДЕЛЬФИЯ');
      expect(philadelphia, findsWidgets);
      await tester.tap(philadelphia.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await _shot(tester, 'offline_product_card_static');

      await tester.tap(find.text('ДОБАВИТЬ В КОРЗИНУ'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await _pop(tester);
      await _pop(tester);

      await _waitBackendDown(tester);

      await tester.tap(find.byKey(const Key('navHome')));
      await tester.pumpAndSettle();
      final navCtx = tester.element(find.byKey(const Key('navHome')));
      Navigator.of(navCtx).push(
        MaterialPageRoute<void>(
          builder: (_) => const ProductsPage(
            title: 'Роллы',
            categoryId: '00000000-0000-0000-0000-000000000001',
          ),
        ),
      );
      await _waitForError(tester);
      _assertFriendlyError();
      await _shot(tester, 'offline_products');
      await _pop(tester);

      await tester.tap(find.byKey(const Key('navProfile')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.ensureVisible(find.text('Мои адреса'));
      await tester.tap(find.text('Мои адреса'));
      await _waitForError(tester);
      _assertFriendlyError();
      await _shot(tester, 'offline_addresses');
      await _pop(tester);

      await tester.ensureVisible(find.byKey(const Key('editProfileEntry')));
      await tester.tap(find.byKey(const Key('editProfileEntry')));
      await _waitForError(tester);
      _assertFriendlyError();
      await _shot(tester, 'offline_edit_profile');
      await _pop(tester);

      await tester.ensureVisible(find.byKey(const Key('supportEntry')));
      await tester.tap(find.byKey(const Key('supportEntry')));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.enterText(
        find.byKey(const Key('supportMessageField')),
        'QA offline support',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('supportSendButton')));
      await _waitForError(tester);
      _assertFriendlyError();
      await _shot(tester, 'offline_support');
      await _pop(tester);

      await tester.tap(find.byKey(const Key('navHome')));
      await tester.pumpAndSettle();
      await _pullToRefresh(tester);
      _assertFriendlyError();
      await _shot(tester, 'offline_home');
      await _shot(tester, 'offline_categories');

      await tester.tap(find.byKey(const Key('navOrders')));
      await tester.pumpAndSettle();
      await _pullToRefresh(tester);
      _assertFriendlyError();
      await _shot(tester, 'offline_orders');

      await tester.tap(find.byKey(const Key('navBasket')));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      if (find.text('ОФОРМИТЬ ЗАКАЗ').evaluate().isNotEmpty) {
        await tester.tap(find.text('ОФОРМИТЬ ЗАКАЗ'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        await _waitForError(tester);
        _assertFriendlyError();
        await _shot(tester, 'offline_cart_quote');
        await _pop(tester);
      }

      await tester.tap(find.byKey(const Key('navProfile')));
      await tester.pumpAndSettle();
      await _pullToRefresh(tester);
      _assertFriendlyError();
      await _shot(tester, 'offline_profile');

      await _waitBackendUp(tester);

      await tester.tap(find.byKey(const Key('navHome')));
      await tester.pumpAndSettle();
      if (find.byKey(const Key('errorRetryButton')).evaluate().isNotEmpty) {
        await _tapRetry(tester);
      }
      expect(find.byType(AppErrorView), findsNothing);
      await _shot(tester, 'retry_home');
      await _shot(tester, 'retry_categories');

      await tester.tap(find.byKey(const Key('navOrders')));
      await tester.pumpAndSettle();
      if (find.byKey(const Key('errorRetryButton')).evaluate().isNotEmpty) {
        await _tapRetry(tester);
      }
      expect(find.byType(AppErrorView), findsNothing);
      await _shot(tester, 'retry_orders');

      await tester.tap(find.byKey(const Key('navProfile')));
      await tester.pumpAndSettle();
      if (find.byKey(const Key('errorRetryButton')).evaluate().isNotEmpty) {
        await _tapRetry(tester);
      }
      expect(find.byType(AppErrorView), findsNothing);
      await _shot(tester, 'retry_profile');

      await tester.tap(find.byKey(const Key('navBasket')));
      await tester.pumpAndSettle();
      if (find.text('ОФОРМИТЬ ЗАКАЗ').evaluate().isNotEmpty) {
        await tester.tap(find.text('ОФОРМИТЬ ЗАКАЗ'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        if (find.byKey(const Key('errorRetryButton')).evaluate().isNotEmpty) {
          await _tapRetry(tester);
        }
        await _shot(tester, 'retry_cart_quote');
        await _pop(tester);
      }

      await tester.tap(find.byKey(const Key('navHome')));
      await tester.pumpAndSettle();
      await _openRollsProducts(tester);
      if (find.byKey(const Key('errorRetryButton')).evaluate().isNotEmpty) {
        await _tapRetry(tester);
      }
      expect(find.textContaining('ФИЛАДЕЛЬФИЯ'), findsWidgets);
      await _shot(tester, 'retry_products');
      await tester.tap(find.textContaining('ФИЛАДЕЛЬФИЯ').first);
      await tester.pumpAndSettle();
      await _shot(tester, 'retry_product_card');
      await _pop(tester);
      await _pop(tester);

      await tester.tap(find.byKey(const Key('navProfile')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Мои адреса'));
      await tester.tap(find.text('Мои адреса'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      if (find.byKey(const Key('errorRetryButton')).evaluate().isNotEmpty) {
        await _tapRetry(tester);
      }
      expect(find.byType(AppErrorView), findsNothing);
      await _shot(tester, 'retry_addresses');
      await _pop(tester);

      await tester.ensureVisible(find.byKey(const Key('editProfileEntry')));
      await tester.tap(find.byKey(const Key('editProfileEntry')));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      if (find.byKey(const Key('errorRetryButton')).evaluate().isNotEmpty) {
        await _tapRetry(tester);
      }
      expect(
        find.textContaining('СОХРАНИТЬ').evaluate().isNotEmpty ||
            find.textContaining('Сохранить').evaluate().isNotEmpty,
        isTrue,
      );
      await _shot(tester, 'retry_edit_profile');
      await _pop(tester);

      await tester.ensureVisible(find.byKey(const Key('supportEntry')));
      await tester.tap(find.byKey(const Key('supportEntry')));
      await tester.pumpAndSettle();
      if (find.byKey(const Key('errorRetryButton')).evaluate().isNotEmpty) {
        await _tapRetry(tester);
      }
      await _shot(tester, 'retry_support');
      await _pop(tester);

      await _login(
        tester,
        email: 'admin@example.com',
        password: 'ChangeMeAdmin123!',
      );
      await tester.tap(find.byKey(const Key('navProfile')));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.ensureVisible(find.byKey(const Key('adminPanelEntry')));
      await tester.tap(find.byKey(const Key('adminPanelEntry')));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byKey(const Key('adminPanelTitle')), findsOneWidget);
      await _shot(tester, 'offline_admin_panel');

      await _waitBackendDown(tester);

      Future<void> openAdminOffline(String label, String shot) async {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await _waitForError(tester);
        _assertFriendlyError();
        await _shot(tester, shot);
        await _pop(tester);
      }

      await openAdminOffline('Список категорий', 'offline_admin_categories');
      await openAdminOffline('Список товаров', 'offline_admin_products');
      await openAdminOffline('Список акций', 'offline_admin_promotions');
      await openAdminOffline('Список заказов', 'offline_admin_orders');
      await openAdminOffline('Список пользователей', 'offline_admin_users');
      await openAdminOffline('Обращения', 'offline_admin_support');

      await _waitBackendUp(tester);

      Future<void> openAdminRetry(String label, String shot) async {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        if (find.byKey(const Key('errorRetryButton')).evaluate().isNotEmpty) {
          await _tapRetry(tester);
        }
        if (find.byType(AppErrorView).evaluate().isNotEmpty) {
          await _tapRetry(tester);
        }
        expect(find.byType(AppErrorView), findsNothing);
        await _shot(tester, shot);
        await _pop(tester);
      }

      await openAdminRetry('Список категорий', 'retry_admin_categories');
      await openAdminRetry('Список товаров', 'retry_admin_products');
      await openAdminRetry('Список акций', 'retry_admin_promotions');
      await openAdminRetry('Список заказов', 'retry_admin_orders');
      await openAdminRetry('Список пользователей', 'retry_admin_users');
      await openAdminRetry('Обращения', 'retry_admin_support');
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
