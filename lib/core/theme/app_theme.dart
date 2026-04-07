import 'package:flutter/material.dart';

class AppTheme {
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F0F0F),

    primaryColor: const Color(0xFFFFC107), // Gold (Sa)

    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(fontSize: 16),
    ),

    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFFC107),
      secondary: Color(0xFF03DAC6),
    ),
  );
}
