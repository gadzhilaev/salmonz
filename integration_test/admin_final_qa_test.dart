/// FINAL QA: admin CRUD, permissions, order status, catalog verify, cleanup.
///
/// UI-driven via WidgetTester (same surfaces as Maestro). Screenshots:
/// `qa/admin_*` and `qa/order_status_*` under integration_test output, then
/// copied to docs/screenshots/qa/ by the runner.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:integration_test/integration_test.dart';
import 'package:salmonz/main.dart' as app;

/// 1x1 PNG (orange pixel).
List<int> _tinyPngBytes() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

class _FixedImagePicker extends ImagePickerPlatform {
  _FixedImagePicker(this.path);
  final String path;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    return XFile(path);
  }

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    return [XFile(path)];
  }
}

Future<void> _frames(WidgetTester tester, int n) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _pump(WidgetTester tester) async {
  await app.main();
  await _frames(tester, 24);
  await tester.pump(const Duration(seconds: 2));
}

Future<void> _logout(WidgetTester tester) async {
  if (find.byKey(const Key('loginEmail')).hitTestable().evaluate().isNotEmpty) {
    return;
  }

  // Pop covered routes. Shell nav can still be in the tree under a pushed page,
  // so require a hit-testable back control / keep popping until logout is tappable.
  for (var i = 0; i < 16; i++) {
    if (find
        .byKey(const Key('loginEmail'))
        .hitTestable()
        .evaluate()
        .isNotEmpty) {
      return;
    }
    if (find
        .byKey(const Key('logoutButton'))
        .hitTestable()
        .evaluate()
        .isNotEmpty) {
      break;
    }
    final back = find.byIcon(Icons.arrow_back_ios_new).hitTestable();
    if (back.evaluate().isNotEmpty) {
      await tester.tap(back.first, warnIfMissed: false);
    } else {
      await tester.binding.handlePopRoute();
    }
    await _frames(tester, 6);
  }

  if (find.byKey(const Key('loginEmail')).hitTestable().evaluate().isNotEmpty) {
    return;
  }

  // Open profile tab if logout isn't already on screen.
  if (find.byKey(const Key('logoutButton')).hitTestable().evaluate().isEmpty) {
    final profile = find.byKey(const Key('navProfile')).hitTestable();
    if (profile.evaluate().isNotEmpty) {
      await tester.tap(profile.first, warnIfMissed: false);
    } else if (find.text('ПРОФИЛЬ').hitTestable().evaluate().isNotEmpty) {
      await tester.tap(
        find.text('ПРОФИЛЬ').hitTestable().last,
        warnIfMissed: false,
      );
    }
    await _frames(tester, 12);
  }

  for (var i = 0; i < 12; i++) {
    final logout = find.byKey(const Key('logoutButton')).hitTestable();
    if (logout.evaluate().isNotEmpty) {
      await tester.tap(logout.first, warnIfMissed: false);
      await _frames(tester, 10);
      break;
    }
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isEmpty) break;
    await tester.drag(scrollable.last, const Offset(0, -280));
    await tester.pump(const Duration(milliseconds: 150));
  }

  for (var i = 0; i < 30; i++) {
    final confirm = find.text('ВЫЙТИ').hitTestable();
    if (confirm.evaluate().isNotEmpty) {
      await tester.tap(confirm.last, warnIfMissed: false);
      break;
    }
    await tester.pump(const Duration(milliseconds: 200));
  }

  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (find
        .byKey(const Key('loginEmail'))
        .hitTestable()
        .evaluate()
        .isNotEmpty) {
      return;
    }
  }
}

Future<void> _login(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await _logout(tester);
  await _waitFor(
    tester,
    find.byKey(const Key('loginEmail')).hitTestable(),
    max: 100,
  );
  await tester.enterText(find.byKey(const Key('loginEmail')), email);
  await tester.enterText(find.byKey(const Key('loginPassword')), password);
  FocusManager.instance.primaryFocus?.unfocus();
  await _frames(tester, 3);
  await tester.tap(find.byKey(const Key('loginSubmit')), warnIfMissed: false);
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (find.byKey(const Key('navHome')).evaluate().isNotEmpty ||
        find.byKey(const Key('homeCategory')).evaluate().isNotEmpty ||
        find.text('ПРОФИЛЬ').evaluate().isNotEmpty ||
        find.text('ГЛАВНАЯ').evaluate().isNotEmpty) {
      break;
    }
  }
  await _frames(tester, 8);
  final loggedIn =
      find.byKey(const Key('navHome')).evaluate().isNotEmpty ||
      find.byKey(const Key('homeCategory')).evaluate().isNotEmpty ||
      find.text('ПРОФИЛЬ').evaluate().isNotEmpty;
  expect(loggedIn, isTrue, reason: 'Expected home after login for $email');
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

Future<void> _shot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await binding.convertFlutterSurfaceToImage();
  await tester.pump();
  await binding.takeScreenshot('qa/$name');
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _openAdmin(WidgetTester tester) async {
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
  await tester.pump(const Duration(milliseconds: 800));
  if (find.byKey(const Key('adminPanelTitle')).evaluate().isEmpty) {
    final label = find.text('Админ панель');
    if (label.evaluate().isNotEmpty) {
      await tester.tap(label, warnIfMissed: false);
    }
  }
  await _waitFor(tester, find.byKey(const Key('adminPanelTitle')));
}

Future<void> _backToAdmin(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    if (find.byKey(const Key('adminPanelTitle')).evaluate().isNotEmpty) {
      return;
    }
    final back = find.byIcon(Icons.arrow_back_ios_new);
    if (back.evaluate().isNotEmpty) {
      await tester.tap(back.first, warnIfMissed: false);
    } else {
      await tester.binding.handlePopRoute();
    }
    await _frames(tester, 8);
  }
  if (find.byKey(const Key('adminPanelTitle')).evaluate().isEmpty) {
    await _openAdmin(tester);
  }
}

Future<void> _deleteIfPresent(
  WidgetTester tester,
  String title, {
  required Key deleteKey,
}) async {
  final tile = find.text(title);
  if (tile.evaluate().isEmpty) return;
  await tester.ensureVisible(tile.first);
  await tester.tap(tile.first);
  await _frames(tester, 12);
  final del = find.byKey(deleteKey);
  if (del.evaluate().isEmpty) {
    await tester.binding.handlePopRoute();
    await _frames(tester, 8);
    return;
  }
  await tester.tap(del);
  await _frames(tester, 15);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'admin final QA CRUD permissions order cleanup',
    (tester) async {
      final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final catName = 'QA_${ts}_cat';
      final catEdit = 'QA_${ts}_cat_edit';
      final catSlug = 'qa-$ts-cat';
      final prodName = 'QA_${ts}_prod';
      final promoTitle = 'QA_${ts}_promo';
      await _pump(tester);

      // Tiny valid PNG written to a temp file for ImagePicker/upload.
      final fixture = File('${Directory.systemTemp.path}/qa_${ts}_fixture.png');
      await fixture.writeAsBytes(_tinyPngBytes(), flush: true);
      ImagePickerPlatform.instance = _FixedImagePicker(fixture.path);

      // --- Permissions: USER must not see admin entry ---
      await _login(
        tester,
        email: 'demo@example.com',
        password: 'ChangeMeDemo123!',
      );
      await tester.tap(find.byKey(const Key('navProfile')));
      await _frames(tester, 12);
      await _shot(binding, tester, 'admin_user_no_panel');
      expect(find.byKey(const Key('adminPanelEntry')), findsNothing);
      expect(find.text('Админ панель'), findsNothing);

      // --- Permissions: ADMIN can access ---
      await _login(
        tester,
        email: 'admin@example.com',
        password: 'ChangeMeAdmin123!',
      );
      await _openAdmin(tester);
      await _shot(binding, tester, 'admin_dashboard');
      await _shot(binding, tester, 'admin_access_ok');
      expect(find.text('Список категорий'), findsOneWidget);
      expect(find.text('Список товаров'), findsOneWidget);
      expect(find.text('Список акций'), findsOneWidget);
      expect(find.text('Список заказов'), findsOneWidget);

      // --- Category create (+ image) ---
      await tester.tap(find.byKey(const Key('adminMenuCategories')));
      await _waitFor(tester, find.byKey(const Key('adminCategoriesAdd')));
      await _shot(binding, tester, 'admin_categories_list');
      await tester.tap(find.byKey(const Key('adminCategoriesAdd')));
      await _frames(tester, 8);
      if (find.byKey(const Key('categoryNameField')).evaluate().isEmpty) {
        await tester.tap(find.byIcon(Icons.add), warnIfMissed: false);
        await _frames(tester, 8);
      }
      await _waitFor(tester, find.byKey(const Key('categoryNameField')));
      await tester.enterText(
        find.byKey(const Key('categoryNameField')),
        catName,
      );
      await tester.enterText(
        find.byKey(const Key('categorySlugField')),
        catSlug,
      );
      await tester.tap(find.byKey(const Key('categoryUploadImage')));
      await _frames(tester, 25);
      await _shot(binding, tester, 'admin_category_create');
      await tester.tap(find.byKey(const Key('categorySaveButton')));
      await _waitFor(tester, find.text(catName));
      await _shot(binding, tester, 'admin_category_created');

      // --- Category edit ---
      await tester.tap(find.text(catName));
      await _waitFor(tester, find.byKey(const Key('categoryNameField')));
      await tester.enterText(
        find.byKey(const Key('categoryNameField')),
        catEdit,
      );
      await _shot(binding, tester, 'admin_category_edit');
      await tester.tap(find.byKey(const Key('categorySaveButton')));
      await _waitFor(tester, find.text(catEdit));
      await _shot(binding, tester, 'admin_category_edited');

      // --- Product create in QA category ---
      await _backToAdmin(tester);
      expect(find.byKey(const Key('adminPanelTitle')), findsOneWidget);
      await tester.ensureVisible(find.text('Список товаров'));
      await tester.tap(find.text('Список товаров'), warnIfMissed: false);
      await _frames(tester, 12);
      await _waitFor(tester, find.byKey(const Key('adminProductsAdd')));
      await _shot(binding, tester, 'admin_products_list');
      await tester.ensureVisible(find.byKey(const Key('adminProductsAdd')));
      await tester.tap(
        find.byKey(const Key('adminProductsAdd')),
        warnIfMissed: false,
      );
      await _frames(tester, 12);
      await _waitFor(tester, find.byKey(const Key('productNameField')));
      await tester.enterText(
        find.byKey(const Key('productNameField')),
        prodName,
      );
      await tester.enterText(find.byKey(const Key('productPriceField')), '999');
      // Select QA category in dropdown
      final catDropdown = find.byType(DropdownButtonFormField<String>);
      if (catDropdown.evaluate().isNotEmpty) {
        await tester.tap(catDropdown);
        await _frames(tester, 8);
        final item = find.text(catEdit).last;
        await tester.tap(item, warnIfMissed: false);
        await _frames(tester, 8);
      }
      await tester.ensureVisible(find.byKey(const Key('productUploadImage')));
      await tester.tap(
        find.byKey(const Key('productUploadImage')),
        warnIfMissed: false,
      );
      await _frames(tester, 40);
      await _shot(binding, tester, 'admin_product_create');
      await tester.ensureVisible(find.byKey(const Key('productSaveButton')));
      await tester.tap(
        find.byKey(const Key('productSaveButton')),
        warnIfMissed: false,
      );
      await _waitFor(tester, find.text(prodName), max: 120);
      await _shot(binding, tester, 'admin_product_created');

      // --- Promotion create ---
      await _backToAdmin(tester);
      expect(find.byKey(const Key('adminPanelTitle')), findsOneWidget);
      await tester.ensureVisible(find.text('Список акций'));
      await tester.tap(find.text('Список акций'), warnIfMissed: false);
      await _frames(tester, 12);
      await _waitFor(tester, find.byKey(const Key('adminPromotionsAdd')));
      await _shot(binding, tester, 'admin_promotions_list');
      await tester.tap(
        find.byKey(const Key('adminPromotionsAdd')),
        warnIfMissed: false,
      );
      await _frames(tester, 8);
      await _waitFor(tester, find.byKey(const Key('promotionTitleField')));
      await tester.enterText(
        find.byKey(const Key('promotionTitleField')),
        promoTitle,
      );
      await tester.tap(
        find.byKey(const Key('promotionUploadImage')),
        warnIfMissed: false,
      );
      await _frames(tester, 40);
      await _shot(binding, tester, 'admin_promotion_create');
      await tester.tap(
        find.byKey(const Key('promotionSaveButton')),
        warnIfMissed: false,
      );
      await _waitFor(tester, find.text(promoTitle), max: 120);
      await _shot(binding, tester, 'admin_promotion_created');

      // --- USER catalog verify ---
      // Home category tiles render name.toUpperCase().
      final catEditUi = catEdit.toUpperCase();
      final promoTitleUi = promoTitle.toUpperCase();
      await _login(
        tester,
        email: 'demo@example.com',
        password: 'ChangeMeDemo123!',
      );
      await tester.tap(find.byKey(const Key('navHome')));
      await _frames(tester, 15);
      // Scroll home for QA category / promo
      for (var i = 0; i < 12; i++) {
        if (find.text(catEditUi).evaluate().isNotEmpty ||
            find.textContaining(catEdit).evaluate().isNotEmpty) {
          break;
        }
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 200));
      }
      final catOnHome = find.text(catEditUi).evaluate().isNotEmpty
          ? find.text(catEditUi)
          : find.textContaining(catEdit);
      expect(catOnHome, findsWidgets);
      await _shot(binding, tester, 'admin_user_sees_category');
      await tester.tap(catOnHome.first);
      await _frames(tester, 25);
      final prodUi = prodName.toUpperCase();
      for (var i = 0; i < 40; i++) {
        if (find.text(prodUi).evaluate().isNotEmpty ||
            find.textContaining(prodName).evaluate().isNotEmpty) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 250));
      }
      final prodOnList = find.text(prodUi).evaluate().isNotEmpty
          ? find.text(prodUi)
          : find.textContaining(prodName);
      expect(prodOnList, findsWidgets);
      await _shot(binding, tester, 'admin_user_sees_product');
      await tester.binding.handlePopRoute();
      await _frames(tester, 12);
      for (var i = 0; i < 12; i++) {
        if (find.text(promoTitleUi).evaluate().isNotEmpty ||
            find.textContaining(promoTitle).evaluate().isNotEmpty) {
          break;
        }
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -280));
        await tester.pump(const Duration(milliseconds: 200));
      }
      final promoOnHome = find.text(promoTitleUi).evaluate().isNotEmpty
          ? find.text(promoTitleUi)
          : find.textContaining(promoTitle);
      expect(promoOnHome, findsWidgets);
      await _shot(binding, tester, 'admin_user_sees_promo');

      // --- Order status: ADMIN changes demo order ---
      await _login(
        tester,
        email: 'admin@example.com',
        password: 'ChangeMeAdmin123!',
      );
      await _openAdmin(tester);
      await tester.tap(find.byKey(const Key('adminMenuOrders')));
      await _waitFor(tester, find.textContaining('SZ-'));
      await _shot(binding, tester, 'order_status_admin_list');

      // Prefer known NEW demo order if present, else first list row
      Finder orderTile = find.text('SZ-MS8NI1AG-MBD7');
      if (orderTile.evaluate().isEmpty) {
        orderTile = find.textContaining('SZ-').first;
      }
      final orderNumber =
          (orderTile.evaluate().first.widget as Text).data ?? 'SZ-';
      await tester.tap(orderTile);
      await _frames(tester, 12);
      await _waitFor(tester, find.text('Сменить статус:'));
      await _shot(binding, tester, 'order_status_before');

      final statusBefore = find.textContaining('Статус: ');
      expect(statusBefore, findsOneWidget);
      final beforeText = (statusBefore.evaluate().first.widget as Text).data!;

      // Invalid transition attempt (always try COMPLETED from non-READY path)
      await tester.tap(find.byKey(const Key('adminOrderStatus_COMPLETED')));
      await _frames(tester, 12);
      await _shot(binding, tester, 'order_status_invalid_attempt');
      // If was NEW, status should remain NEW after invalid COMPLETED
      if (beforeText.contains('NEW')) {
        expect(find.text('Статус: NEW'), findsOneWidget);
      }

      // Valid transition based on current status
      if (find.text('Статус: NEW').evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('adminOrderStatus_CONFIRMED')));
        await _frames(tester, 15);
        expect(find.text('Статус: CONFIRMED'), findsOneWidget);
      } else if (find.text('Статус: CONFIRMED').evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('adminOrderStatus_PREPARING')));
        await _frames(tester, 15);
        expect(find.text('Статус: PREPARING'), findsOneWidget);
      }
      await _shot(binding, tester, 'order_status_after_admin');

      // USER sees updated status
      await _login(
        tester,
        email: 'demo@example.com',
        password: 'ChangeMeDemo123!',
      );
      await tester.tap(find.byKey(const Key('navOrders')));
      await _frames(tester, 15);
      await _shot(binding, tester, 'order_status_user_list');
      if (find.text(orderNumber).evaluate().isNotEmpty) {
        await tester.tap(find.text(orderNumber));
        await _frames(tester, 12);
        await _shot(binding, tester, 'order_status_user_confirmed');
        final userStatus =
            find.textContaining('Подтверждён').evaluate().isNotEmpty ||
            find.textContaining('Готовится').evaluate().isNotEmpty ||
            find.textContaining('Статус:').evaluate().isNotEmpty;
        expect(userStatus, isTrue);
      }

      // --- Cleanup QA_* via ADMIN UI ---
      await _login(
        tester,
        email: 'admin@example.com',
        password: 'ChangeMeAdmin123!',
      );
      await _openAdmin(tester);

      await tester.tap(find.byKey(const Key('adminMenuProducts')));
      await _waitFor(tester, find.text('ВСЕ ТОВАРЫ'));
      await _deleteIfPresent(
        tester,
        prodName,
        deleteKey: const Key('productDeleteButton'),
      );
      await _shot(binding, tester, 'admin_cleanup_products');
      await _backToAdmin(tester);

      await tester.tap(find.byKey(const Key('adminMenuPromotions')));
      await _waitFor(tester, find.text('Акции'));
      await _deleteIfPresent(
        tester,
        promoTitle,
        deleteKey: const Key('promotionDeleteButton'),
      );
      await _shot(binding, tester, 'admin_cleanup_promotions');
      await _backToAdmin(tester);

      await tester.tap(find.byKey(const Key('adminMenuCategories')));
      await _waitFor(tester, find.text('Категории'));
      await _deleteIfPresent(
        tester,
        catEdit,
        deleteKey: const Key('categoryDeleteButton'),
      );
      // Leftover QA Category * from prior smoke runs
      for (final leftover in [
        'QA Category 19484',
        'QA Category 309284',
        'QA Category 715060',
        'QA Category 852879',
      ]) {
        await _deleteIfPresent(
          tester,
          leftover,
          deleteKey: const Key('categoryDeleteButton'),
        );
      }
      await _shot(binding, tester, 'admin_cleanup_categories');
      expect(find.text('Роллы'), findsWidgets);
      expect(find.text(catEdit), findsNothing);
      expect(find.text('QA Category 19484'), findsNothing);

      // Print marker for host log
      // ignore: avoid_print
      print('QA_FINAL_ADMIN_PASS ts=$ts order=$orderNumber');
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
