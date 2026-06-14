import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const Color bg = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceHigh = Color(0xFF242424);

  // Text
  static const Color textPrimary = Color(0xFFE8E8E8);
  static const Color textSecondary = Color(0xFFCCCCCC);
  static const Color textTertiary = Color(0xFF888888);

  // Accent — cream/warm white replaces green everywhere
  static const Color accent = Color(0xFFEBE9DC);
  static const Color accentStrong = Color(0xFFEBE9DC);

  // Borders
  static const Color border = Color(0xFF2A2A2A);
  static const Color borderMid = Color(0xFF333333);

  // Legacy aliases
  static const Color darkBg = bg;
  static const Color darkText = textPrimary;
  static const Color darkMuted = textSecondary;
  static const Color lightBg = Color(0xFFF5F5F5);
  static const Color lightText = Color(0xFF0D0D0D);
  static const Color lightMuted = Color(0xFF444444);
  static const Color accentDeep = Color(0xFFD4D2C6);
  static const Color secondary = Color(0xFFEBE9DC);
  static const Color secondarySoft = Color(0xFFF2F1EB);
  static const Color tertiary = Color(0xFFEBE9DC);
  static const Color accentSoft = Color(0xFFF2F1EB);

  static Color glassFill(bool dark) => dark
      ? Colors.white.withValues(alpha: 0.04)
      : Colors.black.withValues(alpha: 0.04);

  static Color glassFillStrong(bool dark) => dark
      ? Colors.white.withValues(alpha: 0.07)
      : Colors.black.withValues(alpha: 0.07);

  static Color glassBorder(bool dark) => dark ? border : Colors.black12;
}
