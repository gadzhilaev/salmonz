/// Extended USER/ADMIN flows against live local API.
library;

import 'dart:math';

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

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 60,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsOneWidget);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('register new user then reach home', (tester) async {
    await _pump(tester);
    await _logout(tester);

    final suffix = Random().nextInt(1 << 20);
    final email = 'qa_$suffix@example.com';
    await AppServices.instance.auth.register(
      email: email,
      password: 'ChangeMeQa123!',
      name: 'QA User',
    );

    await _login(tester, email: email, password: 'ChangeMeQa123!');
    expect(
      find.byKey(const Key('navHome')).evaluate().isNotEmpty ||
          find.byKey(const Key('homeCategory')).evaluate().isNotEmpty,
      isTrue,
    );
  });

  testWidgets('admin panel visible only for admin', (tester) async {
    await _pump(tester);
    await _login(
      tester,
      email: 'demo@example.com',
      password: 'ChangeMeDemo123!',
    );
    await tester.tap(find.byKey(const Key('navProfile')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byKey(const Key('adminPanelEntry')), findsNothing);

    await _login(
      tester,
      email: 'admin@example.com',
      password: 'ChangeMeAdmin123!',
    );
    final profile = find.byKey(const Key('navProfile'));
    await _waitFor(tester, profile);
    await tester.ensureVisible(profile);
    await tester.tap(profile);
    final adminEntry = find.byKey(const Key('adminPanelEntry'));
    await _waitFor(tester, adminEntry);
    await tester.ensureVisible(adminEntry);
    await tester.tap(adminEntry);
    await _waitFor(tester, find.byKey(const Key('adminPanelTitle')));
  });

  testWidgets('address CRUD and orders tab', (tester) async {
    await _pump(tester);
    await _login(
      tester,
      email: 'demo@example.com',
      password: 'ChangeMeDemo123!',
    );

    final addresses = AppServices.instance.addresses;
    final created = await addresses.create(
      title: 'QA',
      city: 'Москва',
      street: 'Тестовая',
      house: '1',
      apartment: '2',
    );
    expect(created.id, isNotEmpty);

    final list = await addresses.list();
    expect(list.any((a) => a.id == created.id), isTrue);

    await addresses.update(created.id, title: 'QA2', apartment: '3');
    await addresses.delete(created.id);
    final after = await addresses.list();
    expect(after.any((a) => a.id == created.id), isFalse);

    await tester.tap(find.byKey(const Key('navOrders')));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}
