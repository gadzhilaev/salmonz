/// Focused error UI coverage.
///
/// Full network-offline verification requires a simulator and the local API
/// container stopped; this test keeps the retry contract deterministic.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:salmonz/widgets/app_error_view.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('offline error exposes a working retry control', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppErrorView(
            message: 'Не удалось подключиться к серверу',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('appErrorView')), findsOneWidget);
    final retry = find.byKey(const Key('errorRetryButton'));
    expect(retry, findsOneWidget);
    await tester.tap(retry);
    expect(retried, isTrue);
  });
}
