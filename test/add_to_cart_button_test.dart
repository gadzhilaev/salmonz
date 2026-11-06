import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salmonz/widgets/add_to_cart_button.dart';

void main() {
  testWidgets('shows label then switches to qty bar', (tester) async {
    var qty = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return AddToCartButton(
                quantity: qty,
                onAdd: () => setState(() => qty = 1),
                onChanged: (v) => setState(() => qty = v),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('В корзину'), findsOneWidget);
    await tester.tap(find.byKey(const Key('addToCart')));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    expect(find.text('В корзину'), findsNothing);

    await tester.tap(find.byKey(const Key('qtyInc')));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('qtyDec')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('qtyDec')));
    await tester.pump();
    expect(find.text('В корзину'), findsOneWidget);
  });
}
