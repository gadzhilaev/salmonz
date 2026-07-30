import 'package:flutter/widgets.dart';

/// Layout width buckets for Salmonz.
enum AppBreakpoint {
  /// Phones in portrait — bottom navigation.
  compact,

  /// Large phones / small tablets.
  medium,

  /// Tablets and wider — NavigationRail + wider content.
  expanded,
}

class AppBreakpoints {
  AppBreakpoints._();

  static const double compactMax = 600;
  static const double mediumMax = 1024;
  static const double railMin = 840;

  static const double pagePaddingCompact = 16;
  static const double pagePaddingMedium = 24;
  static const double pagePaddingExpanded = 32;

  /// Readable form column on tablets (login, checkout fields, editors).
  static const double formMaxWidth = 720;

  /// Wide but not endless content for lists/grids.
  static const double contentMaxWidth = 1200;

  /// Comfortable card min width for grids.
  static const double cardMinWidth = 220;

  static AppBreakpoint ofWidth(double width) {
    if (width < compactMax) return AppBreakpoint.compact;
    if (width < mediumMax) return AppBreakpoint.medium;
    return AppBreakpoint.expanded;
  }

  static AppBreakpoint of(BuildContext context) =>
      ofWidth(MediaQuery.sizeOf(context).width);

  /// Prefer bottom bar on phones even in landscape (wide but short).
  static bool useNavigationRailForSize(Size size) =>
      size.width >= railMin && size.shortestSide >= compactMax;

  static bool useNavigationRail(double width, {double? shortestSide}) {
    if (shortestSide != null) {
      return width >= railMin && shortestSide >= compactMax;
    }
    return width >= railMin;
  }

  static double pagePadding(double width) {
    final bp = ofWidth(width);
    return switch (bp) {
      AppBreakpoint.compact => pagePaddingCompact,
      AppBreakpoint.medium => pagePaddingMedium,
      AppBreakpoint.expanded => pagePaddingExpanded,
    };
  }

  /// Grid column count from available width and preferred card size.
  static int gridColumns(
    double width, {
    double minCardWidth = cardMinWidth,
    int maxColumns = 4,
  }) {
    if (width <= 0) return 1;
    final raw = (width / minCardWidth).floor();
    return raw.clamp(1, maxColumns);
  }

  /// Slightly larger type scale on tablets (multiplies logical font sizes).
  static double typeScale(double width) {
    final bp = ofWidth(width);
    return switch (bp) {
      AppBreakpoint.compact => 1.0,
      AppBreakpoint.medium => 1.06,
      AppBreakpoint.expanded => 1.12,
    };
  }

  static double controlHeight(double width) {
    final bp = ofWidth(width);
    return switch (bp) {
      AppBreakpoint.compact => 48,
      AppBreakpoint.medium => 52,
      AppBreakpoint.expanded => 56,
    };
  }

  static double iconSize(double width) {
    final bp = ofWidth(width);
    return switch (bp) {
      AppBreakpoint.compact => 22,
      AppBreakpoint.medium => 24,
      AppBreakpoint.expanded => 26,
    };
  }
}
