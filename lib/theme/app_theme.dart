import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static TextTheme _buildTextTheme(TextTheme base, Color body) {
    // Explicitly set Space Grotesk for headings/display, Inter for body
    return base.copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(fontSize: 57, fontWeight: FontWeight.w700, color: body),
      displayMedium: GoogleFonts.spaceGrotesk(fontSize: 45, fontWeight: FontWeight.w700, color: body),
      displaySmall: GoogleFonts.spaceGrotesk(fontSize: 36, fontWeight: FontWeight.w700, color: body),
      headlineLarge: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w700, color: body),
      headlineMedium: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w700, color: body),
      headlineSmall: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w600, color: body),
      titleLarge: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w600, color: body),
      titleMedium: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600, color: body),
      titleSmall: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600, color: body),
      labelLarge: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600, color: body),
      labelMedium: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w500, color: body),
      labelSmall: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w500, color: body),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: body),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: body),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: body),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.dark(
        primary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
      ),
      textTheme: _buildTextTheme(base.textTheme, AppColors.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      dividerColor: AppColors.border,
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Color(0xFF0D0D0D),
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        side: const BorderSide(color: AppColors.borderMid),
        labelStyle: GoogleFonts.spaceGrotesk(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: const StadiumBorder(),
      ),
      inputDecorationTheme: _inputDecoration(),
    );
  }

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: ColorScheme.light(
        primary: AppColors.accentStrong,
        surface: Colors.white,
        outline: Colors.black12,
      ),
      textTheme: _buildTextTheme(base.textTheme, AppColors.lightText),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.lightText,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: AppColors.lightText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.lightMuted),
      dividerColor: Colors.black12,
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Color(0xFF0D0D0D),
        elevation: 0,
      ),
      inputDecorationTheme: _inputDecoration(dark: false),
    );
  }

  static InputDecorationTheme _inputDecoration({bool dark = true}) {
    final borderColor = dark ? AppColors.borderMid : Colors.black12;
    final fill = dark ? AppColors.bg : AppColors.lightBg;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderColor),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      labelStyle: GoogleFonts.spaceGrotesk(
          color: dark ? AppColors.textSecondary : AppColors.lightMuted,
          fontSize: 14),
      hintStyle: GoogleFonts.inter(
          color: dark ? AppColors.textTertiary : AppColors.lightMuted,
          fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
