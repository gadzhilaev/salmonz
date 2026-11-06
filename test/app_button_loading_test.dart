import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salmonz/widgets/app_button.dart';

void main() {
  testWidgets('loading keeps size and blocks tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Сохранить',
            loading: true,
            onPressed: () => taps++,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(taps, 0);

    final box = tester.renderObject<RenderBox>(find.byType(SizedBox).first);
    expect(box.size.height, AppButton.height);
  });
}
