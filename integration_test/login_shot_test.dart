import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:salmonz/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('login shot', (tester) async {
    await app.main();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    // If restored session, logout
    if (find.byKey(const Key('navProfile')).evaluate().isNotEmpty) {
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
    expect(find.byKey(const Key('loginSubmit')), findsOneWidget);
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('01_login');
    await tester.pump(const Duration(seconds: 1));
  });
}
