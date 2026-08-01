/// Keeps an admin session on the admin panel for Maestro offline/retry flows.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:salmonz/main.dart' as app;

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
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byKey(const Key('loginSubmit')).evaluate().isNotEmpty) break;
    }
  }
}

Future<void> _loginAdmin(WidgetTester tester) async {
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
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin panel ready for maestro', (tester) async {
    await _pump(tester);
    await _loginAdmin(tester);
    await tester.tap(find.byKey(const Key('navProfile')));
    await tester.pump(const Duration(seconds: 2));
    final adminEntry = find.byKey(const Key('adminPanelEntry'));
    await tester.ensureVisible(adminEntry);
    await tester.tap(adminEntry, warnIfMissed: false);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byKey(const Key('adminPanelTitle')).evaluate().isNotEmpty) {
        break;
      }
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
    // ignore: avoid_print
    print('QA_MARKER_ADMIN_PANEL_READY');
    // Hold the tree so Maestro can drive the live UI.
    for (var i = 0; i < 900; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}
