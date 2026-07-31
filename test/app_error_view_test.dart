import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salmonz/core/theme/app_theme.dart';
import 'package:salmonz/widgets/app_error_view.dart';

void main() {
  testWidgets('shows message and retry button', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: Scaffold(
          body: AppErrorView(
            message: 'Нет соединения с сервером',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('appErrorView')), findsOneWidget);
    expect(find.text('Нет соединения с сервером'), findsOneWidget);
    expect(find.byKey(const Key('errorRetryButton')), findsOneWidget);
    expect(find.text('ПОВТОРИТЬ'), findsOneWidget);

    await tester.tap(find.byKey(const Key('errorRetryButton')));
    expect(retried, isTrue);
  });

  testWidgets('retry button meets minimum tap target height', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppErrorView(message: 'Ошибка', onRetry: () {}),
        ),
      ),
    );

    final button = tester.widget<SizedBox>(
      find.ancestor(
        of: find.byKey(const Key('errorRetryButton')),
        matching: find.byType(SizedBox),
      ),
    );
    expect(button.height, greaterThanOrEqualTo(48));
  });

  testWidgets('hides retry when onRetry is null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppErrorView(message: 'Ошибка')),
      ),
    );

    expect(find.byKey(const Key('errorRetryButton')), findsNothing);
    expect(find.text('ПОВТОРИТЬ'), findsNothing);
  });
}
