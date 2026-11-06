import 'package:flutter/painting.dart';

/// Consistent spacing scale: 4 / 8 / 12 / 16 / 24 / 32.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets pagePaddingWide = EdgeInsets.symmetric(
    horizontal: lg,
  );
}

/// Limited corner radius set.
abstract final class AppRadii {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 40;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get pillAll => BorderRadius.circular(pill);
}
