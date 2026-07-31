/// Profile offline + home retry only (no cart).
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

Future<void> _login(WidgetTester tester) async {
  if (find.byKey(const Key('loginSubmit')).evaluate().isEmpty) {
    await tester.tap(find.byKey(const Key('navProfile')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    final logout = find.byKey(const Key('logoutButton'));
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
  await tester.enterText(
    find.byKey(const Key('loginEmail')),
    'demo@example.com',
  );
  await tester.enterText(
    find.byKey(const Key('loginPassword')),
    'ChangeMeDemo123!',
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
  // ignore: avoid_print
  print('QA_SHOT:$name');
  await tester.pump(const Duration(seconds: 2));
}

Future<void> _waitError(WidgetTester tester) async {
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (find.text('ПОВТОРИТЬ').evaluate().isNotEmpty) return;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('profile offline and retry', (tester) async {
    await _pump(tester);
    await _login(tester);

    // ignore: avoid_print
    print('QA_MARKER_STOP_BACKEND');
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    await tester.tap(find.byKey(const Key('navHome')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 420));
    await _waitError(tester);
    expect(find.text('ПОВТОРИТЬ'), findsWidgets);
    expect(find.textContaining('DioException'), findsNothing);

    await tester.tap(find.byKey(const Key('navProfile')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 420));
    await _waitError(tester);
    expect(find.text('ПОВТОРИТЬ'), findsWidgets);
    expect(find.textContaining('SocketException'), findsNothing);
    await _shot(tester, 'offline_profile');

    // ignore: avoid_print
    print('QA_MARKER_START_BACKEND');
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    await tester.tap(find.byKey(const Key('navHome')));
    await tester.pumpAndSettle();
    if (find.text('ПОВТОРИТЬ').evaluate().isNotEmpty) {
      await tester.tap(find.text('ПОВТОРИТЬ').first);
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 250));
        if (find.text('ПОВТОРИТЬ').evaluate().isEmpty) break;
      }
    }
    expect(find.byType(AppErrorView), findsNothing);
    await _shot(tester, 'retry_home');

    await tester.tap(find.byKey(const Key('navProfile')));
    await tester.pumpAndSettle();
    if (find.text('ПОВТОРИТЬ').evaluate().isNotEmpty) {
      await tester.tap(find.text('ПОВТОРИТЬ').first);
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 250));
        if (find.text('ПОВТОРИТЬ').evaluate().isEmpty) break;
      }
    }
    expect(find.byType(AppErrorView), findsNothing);
    await _shot(tester, 'retry_profile');

    await tester.tap(find.byKey(const Key('navOrders')));
    await tester.pumpAndSettle();
    if (find.text('ПОВТОРИТЬ').evaluate().isNotEmpty) {
      await tester.tap(find.text('ПОВТОРИТЬ').first);
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 250));
        if (find.text('ПОВТОРИТЬ').evaluate().isEmpty) break;
      }
    }
    await _shot(tester, 'retry_orders');
  }, timeout: const Timeout(Duration(minutes: 8)));
}
