import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFFFE8501);
  static const primaryAlt = Color(0xFFFB3A02);
  static const secondary = Color(0xFF022EA7);
  static const accent = Color(0xFF8FA0D7);
  static const surfaceCream = Color(0xFFF8DFC7);
  static const ink = Color(0xFF0C0728);
  static const bg = Color(0xFFFCFCFC);
  static const muted = Color(0xFF656B93);
  static const success = Color(0xFF1DAA61);
  static const border = Color(0xFFEDEAE3);

  static const blue = secondary;
  static const brightBlue = secondary;
  static const orange = primaryAlt;
  static const orange2 = primary;
  static const text = ink;
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primary,
        scaffoldBackgroundColor: AppColors.bg);
    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink.withValues(alpha: .87),
      displayColor: AppColors.ink,
    );
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: Colors.white,
        error: AppColors.primaryAlt,
      ),
      textTheme: textTheme.copyWith(
        displayLarge:
            textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w800),
        displayMedium:
            textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800),
        headlineLarge:
            textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        headlineMedium:
            textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: AppColors.ink.withValues(alpha: .87),
        ),
        labelSmall: textTheme.labelSmall?.copyWith(color: AppColors.muted),
      ),
      cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: AppColors.muted),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.secondary, width: 1.4))),
    );
  }
}

LinearGradient brandGradient() => const LinearGradient(
    colors: [AppColors.secondary, AppColors.ink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight);
LinearGradient orangeGradient() => const LinearGradient(
    colors: [AppColors.primary, AppColors.primaryAlt],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight);
