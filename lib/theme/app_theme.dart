import 'package:flutter/material.dart';

class AppColors {
  // --- New palette ---
  static const background = Color(0xFFFFF8FA);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFFE8A7B5);
  static const primaryDark = Color(0xFFC9788D);
  static const accent = Color(0xFFD9A7B1);
  static const border = Color(0xFFF0DDE2);
  static const textPrimary = Color(0xFF2E2E2E);
  static const textSecondary = Color(0xFF777777);
  static const success = Color(0xFF4CAF7F);
  static const error = Color(0xFFE57373);
  static const white = Color(0xFFFFFFFF);

  // --- Old names, kept so unconverted screens still compile ---
  static const cream = background;
  static const rose = primary;
  static const blush = accent;
  static const blushSoft = Color(0xFFF6E6E9);
  static const sand = border;
  static const muted = textSecondary;
  static const cocoa = textPrimary;
}

class AppText {
  static TextStyle display(double size,
          {Color color = AppColors.textPrimary, FontWeight w = FontWeight.w600}) =>
      TextStyle(
        fontFamily: 'serif',
        fontFamilyFallback: const ['Georgia', 'Times New Roman'],
        fontSize: size,
        color: color,
        fontWeight: w,
        height: 1.15,
        letterSpacing: 0.2,
      );

  static TextStyle body(double size,
          {Color color = AppColors.textPrimary, FontWeight w = FontWeight.w400}) =>
      TextStyle(fontSize: size, color: color, fontWeight: w, height: 1.4);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            surface: AppColors.background,
            primary: AppColors.primary,
            error: AppColors.error),
        appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            foregroundColor: AppColors.textPrimary),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            minimumSize: const Size.fromHeight(54),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryDark,
            minimumSize: const Size.fromHeight(54),
            side: const BorderSide(color: AppColors.primary, width: 1.2),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme:
            TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: AppColors.primaryDark)),
      );
}