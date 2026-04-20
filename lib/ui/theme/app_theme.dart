import 'package:flutter/material.dart';

class AppColors {
  static const Color baseSurface = Color(0xFFECEEF1);
  static const Color baseSurfaceAlt = Color(0xFFEEEFF2);
  static const Color surface = Color(0xFFFDFDFD);
  static const Color mapBackground = Color(0xFFD0D2D7);

  static const Color textPrimary = Color(0xFF090909);
  static const Color iconPrimary = Color(0xFF050607);
  static const Color slate = Color(0xFF313A47);
  static const Color neutralText = Color(0xFF55575C);
  static const Color muted = Color(0xFFA8B5AE);
  static const Color scanButtonDark = Color(0xFF202A3A);

  static const Color success = Color(0xFF11B982);
  static const Color successAlt = Color(0xFF09B77D);
  static const Color warning = Color(0xFFD85915);
  static const Color warningAlt = Color(0xFFD9531E);
}

ThemeData get appTheme {
  return ThemeData(
    useMaterial3: false,
    scaffoldBackgroundColor: AppColors.baseSurfaceAlt,
    colorScheme: const ColorScheme.light(
      primary: AppColors.warning,
      secondary: AppColors.success,
      surface: AppColors.surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textPrimary),
      titleMedium: TextStyle(color: AppColors.textPrimary),
      titleLarge: TextStyle(color: AppColors.textPrimary),
    ),
    cardColor: AppColors.surface,
    dividerColor: AppColors.baseSurface,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.baseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.slate,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
  );
}
