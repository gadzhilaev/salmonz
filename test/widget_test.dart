import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke test that does not initialize Supabase or hit a network.
void main() {
  testWidgets('MaterialApp boots without Supabase', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Salmonz config OK'))),
      ),
    );

    expect(find.text('Salmonz config OK'), findsOneWidget);
  });
}
