import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salmonz/core/theme/app_theme.dart';

/// Smoke test that does not hit the network.
void main() {
  testWidgets('MaterialApp boots with Salmonz themes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const Scaffold(body: Center(child: Text('Salmonz config OK'))),
      ),
    );

    expect(find.text('Salmonz config OK'), findsOneWidget);
  });
}
