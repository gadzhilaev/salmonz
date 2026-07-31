/// Opens each admin editor and creates a disposable QA category through UI.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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

Future<void> _openAdmin(WidgetTester tester) async {
  await _frames(tester, 16);
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 200));
    if (find.byKey(const Key('loginSubmit')).evaluate().isNotEmpty ||
        find.byKey(const Key('navProfile')).evaluate().isNotEmpty) {
      break;
    }
  }
  if (find.byKey(const Key('loginSubmit')).evaluate().isNotEmpty) {
    await tester.enterText(
      find.byKey(const Key('loginEmail')),
      'admin@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('loginPassword')),
      'ChangeMeAdmin123!',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('loginSubmit')));
    await _waitFor(tester, find.byKey(const Key('navProfile')));
  }
  await tester.tap(find.byKey(const Key('navProfile')));
  await _waitFor(tester, find.byKey(const Key('adminPanelEntry')));
  for (var i = 0; i < 6; i++) {
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isEmpty) break;
    await tester.drag(scrollable.last, const Offset(0, -220));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.tap(
    find.byKey(const Key('adminPanelEntry')),
    warnIfMissed: false,
  );
  await _frames(tester, 15);
  if (find.byKey(const Key('adminPanelTitle')).evaluate().isEmpty) {
    final label = find.text('Админ панель');
    if (label.evaluate().isNotEmpty) {
      await tester.tap(label, warnIfMissed: false);
    }
  }
  await _waitFor(tester, find.byKey(const Key('adminPanelTitle')));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin category create and product/promotion editors', (
    tester,
  ) async {
    await app.main();
    await _openAdmin(tester);

    await tester.tap(find.byKey(const Key('adminMenuCategories')));
    final addCategory = find.byKey(const Key('adminCategoriesAdd'));
    await _waitFor(tester, addCategory);
    await tester.tap(addCategory, warnIfMissed: false);
    await _frames(tester, 15);
    if (find.byKey(const Key('categoryNameField')).evaluate().isEmpty) {
      await tester.tap(find.byIcon(Icons.add), warnIfMissed: false);
    }
    await _waitFor(tester, find.byKey(const Key('categoryNameField')));
    final suffix = Random().nextInt(1 << 20);
    final name = 'QA Category $suffix';
    await tester.enterText(find.byKey(const Key('categoryNameField')), name);
    await tester.enterText(
      find.byKey(const Key('categorySlugField')),
      'qa-category-$suffix',
    );
    await tester.tap(find.byKey(const Key('categorySaveButton')));
    await _waitFor(tester, find.text(name));

    // Fresh open for products editor.
    await tester.binding.handlePopRoute();
    await _frames(tester, 10);
    if (find.byKey(const Key('adminPanelTitle')).evaluate().isEmpty) {
      await _openAdmin(tester);
    }
    await tester.tap(find.byKey(const Key('adminMenuProducts')));
    await _waitFor(tester, find.byKey(const Key('adminProductsAdd')));
    await tester.tap(
      find.byKey(const Key('adminProductsAdd')),
      warnIfMissed: false,
    );
    await _frames(tester, 15);
    if (find.byKey(const Key('productNameField')).evaluate().isEmpty) {
      await tester.tap(find.byIcon(Icons.add), warnIfMissed: false);
    }
    await _waitFor(tester, find.byKey(const Key('productNameField')));
    expect(find.byKey(const Key('productPriceField')), findsOneWidget);
    expect(find.byKey(const Key('productSaveButton')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await _frames(tester, 10);
    await tester.binding.handlePopRoute();
    await _frames(tester, 10);
    if (find.byKey(const Key('adminPanelTitle')).evaluate().isEmpty) {
      await _openAdmin(tester);
    }
    await tester.tap(find.byKey(const Key('adminMenuPromotions')));
    await _waitFor(tester, find.byKey(const Key('adminPromotionsAdd')));
    await tester.tap(
      find.byKey(const Key('adminPromotionsAdd')),
      warnIfMissed: false,
    );
    await _frames(tester, 15);
    if (find.byKey(const Key('promotionTitleField')).evaluate().isEmpty) {
      await tester.tap(find.byIcon(Icons.add), warnIfMissed: false);
    }
    await _waitFor(tester, find.byKey(const Key('promotionTitleField')));
    expect(find.byKey(const Key('promotionSaveButton')), findsOneWidget);
  });
}
