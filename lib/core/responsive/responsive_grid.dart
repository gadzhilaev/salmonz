import 'package:flutter/material.dart';

import 'app_breakpoints.dart';

/// Adaptive wrap/grid that fills available width with comfortable card sizes.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.minCardWidth = AppBreakpoints.cardMinWidth,
    this.maxColumns = 4,
    this.spacing = 12,
    this.runSpacing = 12,
    this.childAspectRatio,
    this.itemHeight,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index, double tileWidth)
  itemBuilder;
  final double minCardWidth;
  final int maxColumns;
  final double spacing;
  final double runSpacing;

  /// If set, preferred height from width / ratio. Ignored when [itemHeight] set.
  final double? childAspectRatio;
  final double? itemHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        var columns = AppBreakpoints.gridColumns(
          maxW,
          minCardWidth: minCardWidth,
          maxColumns: maxColumns,
        );
        if (itemCount > 0 && itemCount < columns) {
          columns = itemCount;
        }
        final tileW = (maxW - spacing * (columns - 1)) / columns;
        final h =
            itemHeight ??
            (childAspectRatio != null
                ? tileW / childAspectRatio!
                : tileW * 0.72);

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: List.generate(itemCount, (i) {
            return SizedBox(
              width: tileW,
              height: h,
              child: itemBuilder(context, i, tileW),
            );
          }),
        );
      },
    );
  }
}
