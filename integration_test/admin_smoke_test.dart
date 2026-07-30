/// Admin smoke integration test against live local API.
///
/// ```bash
/// flutter test integration_test/admin_smoke_test.dart -d <device> --dart-define-from-file=config/local.json
/// ```
///
/// Admin credentials (seeded by backend):
/// - admin@example.com / ChangeMeAdmin123!
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:salmonz/main.dart' as app;

Future<void> _ensureLoggedOut(WidgetTester tester) async {
  if (find.byKey(const Key('loginSubmit')).evaluate().isNotEmpty) return;

  if (find.byKey(const Key('navProfile')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('navProfile')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin login opens admin panel', (tester) async {
    await app.main();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await _ensureLoggedOut(tester);

    final emailField = find.byKey(const Key('loginEmail'));
    final passField = find.byKey(const Key('loginPassword'));
    await tester.tap(emailField);
    await tester.enterText(emailField, 'admin@example.com');
    await tester.tap(passField);
    await tester.enterText(passField, 'ChangeMeAdmin123!');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('loginSubmit')));

    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byKey(const Key('navProfile')).evaluate().isNotEmpty) break;
    }
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final navProfile = find.byKey(const Key('navProfile'));
    expect(navProfile, findsOneWidget);
    await tester.tap(navProfile);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final adminEntry = find.byKey(const Key('adminPanelEntry'));
    expect(adminEntry, findsOneWidget);
    await tester.ensureVisible(adminEntry);
    await tester.pumpAndSettle();
    await tester.tap(adminEntry, warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(
      find.textContaining('АДМИН').evaluate().isNotEmpty ||
          find.textContaining('Админ').evaluate().isNotEmpty ||
          find.textContaining('категор').evaluate().isNotEmpty,
      isTrue,
      reason: 'Admin panel content should be visible after opening entry',
    );
  });
}
