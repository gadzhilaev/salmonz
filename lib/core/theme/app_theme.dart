import 'package:flutter/material.dart';

/// Salmonz brand colors and Material 3 themes.
class AppTheme {
  static const Color orange = Color(0xFFFF5E1C);
  static const Color darkGreen = Color(0xFF26351E);
  static const Color secondaryText = Color(0xFF282828);

  /// Dark surfaces (not a simple invert of light).
  static const Color darkBg = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkSurfaceElevated = Color(0xFF2C2C2E);
  static const Color darkOnSurface = Color(0xFFF2F2F7);
  static const Color darkOnSurfaceMuted = Color(0xFFAEAEB2);

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
      dividerColor: const Color(0xFFE5E5E5),
    );
  }

  static ThemeData get dark {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: orange,
          primary: orange,
          secondary: const Color(0xFF8FA882),
          brightness: Brightness.dark,
          surface: darkSurface,
          onSurface: darkOnSurface,
        ).copyWith(
          primary: orange,
          onPrimary: Colors.white,
          surfaceContainerHighest: darkSurfaceElevated,
          outline: const Color(0xFF3A3A3C),
        );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: darkBg,
      canvasColor: darkBg,
      cardColor: darkSurface,
      dialogTheme: const DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: darkOnSurface,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: orange),
      dividerColor: const Color(0xFF3A3A3C),
      textTheme: Typography.material2021(
        platform: TargetPlatform.android,
      ).white.apply(bodyColor: darkOnSurface, displayColor: darkOnSurface),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: darkOnSurfaceMuted.withValues(alpha: 0.8)),
      ),
    );
  }
}
