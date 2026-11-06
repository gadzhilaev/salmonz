import 'package:flutter/material.dart';

/// Softened Salmonz brand palette — orange for CTAs, forest for structure.
abstract final class AppColors {
  // Brand
  static const Color orange = Color(0xFFE8683A);
  static const Color orangeStrong = Color(0xFFD4552A);
  static const Color orangeSoft = Color(0xFFFFE8DF);
  static const Color forest = Color(0xFF2C3B26);
  static const Color forestMuted = Color(0xFF5A6B54);

  // Light neutrals
  static const Color lightBg = Color(0xFFF7F7F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF0F0ED);
  static const Color lightBorder = Color(0xFFE4E4E0);
  static const Color lightText = Color(0xFF1C2419);
  static const Color lightTextMuted = Color(0xFF6B7368);

  // Dark neutrals
  static const Color darkBg = Color(0xFF121512);
  static const Color darkSurface = Color(0xFF1B1F1B);
  static const Color darkSurfaceElevated = Color(0xFF262B26);
  static const Color darkBorder = Color(0xFF343A34);
  static const Color darkText = Color(0xFFF2F4F1);
  static const Color darkTextMuted = Color(0xFFA8B0A6);

  // Semantic
  static const Color success = Color(0xFF2F9E6B);
  static const Color warning = Color(0xFFD4A017);
  static const Color error = Color(0xFFC94A3A);
  static const Color info = Color(0xFF3A7CA5);
}
