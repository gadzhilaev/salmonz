/// Admin smoke integration test against live local API.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:salmonz/main.dart' as app;

Future<void> _frames(WidgetTester tester, int n) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin login opens admin panel', (tester) async {
    await app.main();
    await _frames(tester, 25);

    final onLogin = find.byKey(const Key('loginSubmit')).evaluate().isNotEmpty;
    if (onLogin) {
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
      await _frames(tester, 60);
    }

    expect(
      find.byKey(const Key('navProfile')).evaluate().isNotEmpty,
      isTrue,
      reason: 'Expected app chrome after admin session',
    );

    await tester.tap(find.byKey(const Key('navProfile')));
    await _frames(tester, 30);

    final adminEntry = find.byKey(const Key('adminPanelEntry'));
    expect(adminEntry, findsOneWidget);

    // Nudge list upward a few times; avoid ensureVisible (can hang).
    for (var i = 0; i < 5; i++) {
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isEmpty) break;
      await tester.drag(scrollable.last, const Offset(0, -200));
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.tap(adminEntry);
    await _frames(tester, 40);

    if (find.byKey(const Key('adminPanelTitle')).evaluate().isEmpty) {
      await tester.tap(find.text('Админ панель'));
      await _frames(tester, 40);
    }

    expect(find.byKey(const Key('adminPanelTitle')), findsOneWidget);
    expect(find.byKey(const Key('adminMenuCategories')), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
