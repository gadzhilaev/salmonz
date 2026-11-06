import 'package:flutter/material.dart';

import '../core/money/money.dart';

class PriceText extends StatelessWidget {
  const PriceText(this.money, {super.key, this.style, this.suffix = ' ₽'});

  final Money money;
  final TextStyle? style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final base =
        style ??
        Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    return Text('${money.format()}$suffix', style: base);
  }
}
