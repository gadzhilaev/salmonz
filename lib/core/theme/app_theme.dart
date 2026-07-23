import 'package:flutter/material.dart';

/// Salmonz brand colors and Material 3 themes.
class AppTheme {
  static const Color orange = Color(0xFFFF5E1C);
  static const Color darkGreen = Color(0xFF26351E);
  static const Color secondaryText = Color(0xFF282828);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: orange,
      primary: orange,
      secondary: darkGreen,
      brightness: Brightness.light,
      surface: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: darkGreen,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: orange),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: orange,
      primary: orange,
      secondary: darkGreen,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: orange),
    );
  }
}
