import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single typeface (Plus Jakarta Sans) + Material text scale.
abstract final class AppTypography {
  static String get fontFamily =>
      GoogleFonts.plusJakartaSans().fontFamily ?? 'PlusJakartaSans';

  static TextStyle _jakarta({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double height = 1.3,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextTheme textTheme(Brightness brightness) {
    final onSurface = brightness == Brightness.dark
        ? const Color(0xFFF2F4F1)
        : const Color(0xFF1C2419);
    final muted = brightness == Brightness.dark
        ? const Color(0xFFA8B0A6)
        : const Color(0xFF6B7368);

    return TextTheme(
      displayLarge: _jakarta(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.3,
        color: onSurface,
      ),
      headlineLarge: _jakarta(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.2,
        color: onSurface,
      ),
      headlineMedium: _jakarta(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      titleLarge: _jakarta(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleMedium: _jakarta(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleSmall: _jakarta(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: _jakarta(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: onSurface,
      ),
      bodyMedium: _jakarta(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: onSurface,
      ),
      bodySmall: _jakarta(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: muted,
      ),
      labelLarge: _jakarta(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: onSurface,
      ),
      labelMedium: _jakarta(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: muted,
      ),
      labelSmall: _jakarta(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: muted,
      ),
    );
  }
}
