import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salmonz/widgets/app_empty_state.dart';

void main() {
  testWidgets('shows title subtitle and action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppEmptyState(
            title: 'Заказов пока нет',
            message: 'Оформите первый заказ',
            actionLabel: 'Посмотреть меню',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Заказов пока нет'), findsOneWidget);
    expect(find.text('Оформите первый заказ'), findsOneWidget);
    await tester.tap(find.text('Посмотреть меню'));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
