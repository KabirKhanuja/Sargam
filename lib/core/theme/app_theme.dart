import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppColors.gold,
      onPrimary: Color(0xFF1B1300),
      secondary: AppColors.goldSoft,
      onSecondary: Color(0xFF1B1300),
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceHigh,
      outline: AppColors.divider,
      error: AppColors.offPitch,
      onError: Colors.white,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 96,
        fontWeight: FontWeight.w300,
        letterSpacing: -2,
        color: AppColors.gold,
      ),
      displayMedium: TextStyle(
        fontSize: 64,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
        color: AppColors.textPrimary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        letterSpacing: 1.4,
        color: AppColors.textMuted,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    dividerColor: AppColors.divider,
    iconTheme: const IconThemeData(color: AppColors.textSecondary),
  );
}
