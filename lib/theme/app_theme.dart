import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF087E8B);
  static const Color darkTeal = Color(0xFF064B55);
  static const Color navy = Color(0xFF102A43);
  static const Color background = Color(0xFFF5F8FA);
  static const Color muted = Color(0xFF718096);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: Colors.white,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: navy,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
