import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salmonz/core/theme/app_colors.dart';
import 'package:salmonz/widgets/app_notice.dart';

void main() {
  testWidgets('AppNotice.error uses error color and hides duplicates', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppNotice.error(context, 'Ошибка А');
                  AppNotice.error(context, 'Ошибка Б');
                },
                child: const Text('go'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pump();
    expect(find.text('Ошибка А'), findsNothing);
    expect(find.text('Ошибка Б'), findsOneWidget);

    final snack = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snack.backgroundColor, AppColors.error);
  });

  testWidgets('AppNotice suppresses «Требуется авторизация»', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppNotice.error(context, 'Требуется авторизация');
                  AppNotice.info(context, 'Unauthorized');
                },
                child: const Text('go'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pump();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('AppNotice.success is green, not used for auth errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => AppNotice.success(context, 'Заказ оформлен'),
                child: const Text('go'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    final snack = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snack.backgroundColor, AppColors.success);
  });
}
