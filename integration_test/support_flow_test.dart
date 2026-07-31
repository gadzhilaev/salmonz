/// USER support submission followed by ADMIN support inbox visibility.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:salmonz/auth/login.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/main.dart' as app;

Future<void> _frames(WidgetTester tester, int n) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  int max = 80,
}) async {
  for (var i = 0; i < max; i++) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets);
}

Future<void> _logoutIfNeeded(WidgetTester tester) async {
  if (find.byKey(const Key('loginSubmit')).evaluate().isNotEmpty) return;
  if (find.byKey(const Key('navProfile')).evaluate().isEmpty) return;
  await tester.tap(find.byKey(const Key('navProfile')));
  await _waitFor(tester, find.byKey(const Key('logoutButton')));
  await tester.tap(find.byKey(const Key('logoutButton')));
  await _waitFor(tester, find.text('ВЫЙТИ'));
  await tester.tap(find.text('ВЫЙТИ').last);
  await _waitFor(tester, find.byKey(const Key('loginSubmit')));
}

Future<void> _login(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await _logoutIfNeeded(tester);
  await _waitFor(tester, find.byKey(const Key('loginEmail')));
  await tester.enterText(find.byKey(const Key('loginEmail')), email);
  await tester.enterText(find.byKey(const Key('loginPassword')), password);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(find.byKey(const Key('loginSubmit')));
  await _waitFor(tester, find.byKey(const Key('navProfile')));
}

Future<void> _scrollProfile(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isEmpty) break;
    await tester.drag(scrollable.last, const Offset(0, -220));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('user message is visible to admin', (tester) async {
    await app.main();
    await _frames(tester, 20);
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.byKey(const Key('loginSubmit')).evaluate().isNotEmpty ||
          find.byKey(const Key('navProfile')).evaluate().isNotEmpty) {
        break;
      }
    }

    await _login(
      tester,
      email: 'demo@example.com',
      password: 'ChangeMeDemo123!',
    );
    await tester.tap(find.byKey(const Key('navProfile')));
    await _frames(tester, 20);
    // Profile tiles load asynchronously with getMe.
    for (var i = 0; i < 8; i++) {
      if (find.byKey(const Key('supportEntry')).evaluate().isNotEmpty) break;
      await _scrollProfile(tester);
      await _frames(tester, 5);
    }
    final supportEntry = find.byKey(const Key('supportEntry'));
    await _waitFor(tester, supportEntry, max: 100);
    await tester.tap(supportEntry, warnIfMissed: false);

    final message = 'QA_support_${Random().nextInt(1 << 20)}';
    final messageField = find.byKey(const Key('supportMessageField'));
    await _waitFor(tester, messageField);
    await tester.enterText(messageField, message);
    await tester.tap(find.byKey(const Key('supportSendButton')));
    await _waitFor(tester, find.text('Внимание!'));
    await tester.tap(find.text('ОК'));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.text('Внимание!').evaluate().isEmpty &&
          find.byKey(const Key('navProfile')).evaluate().isNotEmpty) {
        break;
      }
    }

    // Switch account: clear tokens and open login without relying on obscured nav.
    await AppServices.instance.auth.logout();
    final navContext = tester.element(find.byKey(const Key('navProfile')));
    Navigator.of(navContext, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const Login()),
      (_) => false,
    );
    await _frames(tester, 10);
    await _login(
      tester,
      email: 'admin@example.com',
      password: 'ChangeMeAdmin123!',
    );
    await tester.tap(find.byKey(const Key('navProfile')));
    await _frames(tester, 20);
    for (var i = 0; i < 10; i++) {
      if (find.byKey(const Key('adminPanelEntry')).evaluate().isNotEmpty) break;
      await _scrollProfile(tester);
      await _frames(tester, 5);
    }
    final adminEntry = find.byKey(const Key('adminPanelEntry'));
    await _waitFor(tester, adminEntry, max: 100);
    for (var i = 0; i < 6; i++) {
      await _scrollProfile(tester);
    }
    await tester.tap(adminEntry, warnIfMissed: false);
    await _frames(tester, 20);
    if (find.byKey(const Key('adminPanelTitle')).evaluate().isEmpty) {
      final label = find.text('Админ панель');
      if (label.evaluate().isNotEmpty) {
        await tester.tap(label, warnIfMissed: false);
      }
    }
    await _waitFor(tester, find.byKey(const Key('adminPanelTitle')), max: 100);
    await tester.tap(find.byKey(const Key('adminMenuSupport')));
    await _waitFor(tester, find.byKey(const Key('adminSupportTitle')));
    await _waitFor(tester, find.text(message));
  });
}
