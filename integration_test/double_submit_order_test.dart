/// Double-submit order protection via checkout UI.
///
/// Setup helpers may use repositories for fixtures (address/product/cart).
/// Order creation itself is asserted through the checkout button and API count.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:salmonz/core/di/app_services.dart';
import 'package:salmonz/main.dart' as app;
import 'package:salmonz/widgets/cart.dart';

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 80,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsOneWidget);
}

Future<void> _logoutIfNeeded(WidgetTester tester) async {
  if (find.byKey(const Key('loginSubmit')).evaluate().isNotEmpty) return;
  final profile = find.byKey(const Key('navProfile'));
  if (profile.evaluate().isEmpty) return;
  await tester.tap(profile);
  await _waitFor(tester, find.byKey(const Key('logoutButton')));
  await tester.tap(find.byKey(const Key('logoutButton')));
  await _waitFor(tester, find.text('ВЫЙТИ'));
  await tester.tap(find.text('ВЫЙТИ').last);
  await _waitFor(tester, find.byKey(const Key('loginSubmit')));
}

Future<void> _loginDemo(WidgetTester tester) async {
  await _logoutIfNeeded(tester);
  if (find.byKey(const Key('loginSubmit')).evaluate().isEmpty) {
    await _waitFor(tester, find.byKey(const Key('navBasket')));
    return;
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
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(find.byKey(const Key('loginSubmit')));
  await _waitFor(tester, find.byKey(const Key('navBasket')));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('double tap create-order yields a single order', (tester) async {
    await app.main();
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await _loginDemo(tester);

    final services = AppServices.instance;
    final addresses = await services.addresses.list();
    if (addresses.isEmpty) {
      await services.addresses.create(
        title: 'QA Double Submit',
        city: 'Москва',
        street: 'Тестовая',
        house: '1',
        apartment: '1',
      );
    }

    final page = await services.catalog.getProducts(limit: 5);
    expect(page.data, isNotEmpty, reason: 'Seed catalog must include products');
    final product = page.data.first;

    await Cart.instance.clear();
    Cart.instance.add(
      CartItem(
        id: product.id,
        name: product.name,
        img: product.imageUrl ?? '',
        price: product.price,
        gramm: product.weight ?? 0,
        amount: 1,
        qty: 1,
      ),
    );

    final before = await services.orders.list();
    final beforeIds = before.map((o) => o.id).toSet();

    await tester.tap(find.byKey(const Key('navBasket')));
    await _waitFor(tester, find.byKey(const Key('cartCheckoutButton')));
    await tester.tap(find.byKey(const Key('cartCheckoutButton')));

    final create = find.byKey(const Key('checkoutCreateOrder'));
    await _waitFor(tester, create, maxPumps: 100);

    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      final btn = tester.widget<ElevatedButton>(create);
      if (btn.onPressed != null) break;
    }

    final phoneField = find.byKey(const Key('checkoutPhone'));
    if (phoneField.evaluate().isNotEmpty) {
      await tester.enterText(phoneField, '+7 900 000-00-00');
      await tester.pump(const Duration(milliseconds: 200));
    }

    for (var i = 0; i < 10; i++) {
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isEmpty) break;
      await tester.drag(scrollable.last, const Offset(0, -260));
      await tester.pump(const Duration(milliseconds: 120));
      final rect = tester.getRect(create);
      final h = tester.view.physicalSize.height / tester.view.devicePixelRatio;
      if (rect.bottom < h - 8 && rect.top > 0) break;
    }

    // Prefer real taps; fall back to invoking onPressed when hit-tests miss
    // (button still in tree but below the visible viewport on some sims).
    final beforeBtn = tester.widget<ElevatedButton>(create);
    expect(beforeBtn.onPressed, isNotNull);
    await tester.tap(create, warnIfMissed: false);
    await tester.pump();
    if (tester.widget<ElevatedButton>(create).onPressed != null) {
      beforeBtn.onPressed!.call();
      await tester.pump();
    }
    await tester.tap(create, warnIfMissed: false);
    await tester.pump();

    if (create.evaluate().isNotEmpty) {
      final mid = tester.widget<ElevatedButton>(create);
      expect(
        mid.onPressed,
        isNull,
        reason: 'Create order must lock after first tap',
      );
    }

    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byKey(const Key('checkoutCreateOrder')).evaluate().isEmpty) {
        break;
      }
    }

    final after = await services.orders.list();
    final created = after.where((o) => !beforeIds.contains(o.id)).toList();
    expect(
      created.length,
      1,
      reason: 'Exactly one new order must be created on double-submit',
    );
  });
}
