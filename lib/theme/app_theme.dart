import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primaryRed = Color(0xFFFF4444);
  static const Color accentYellow = Color(0xFFFFD600);
  static const Color accentBlue = Color(0xFF00B0FF);
  static const Color accentGreen = Color(0xFF00E676);
  static const Color background = Color(0xFFF0F4F8);
  static const Color deepPurple = Color(0xFF6200EA);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textLight = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.fredoka().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryRed,
        primary: AppColors.primaryRed,
        secondary: AppColors.accentBlue,
        tertiary: AppColors.accentYellow,
        surface: AppColors.background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 4,
          textStyle: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.fredoka(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        titleLarge: GoogleFonts.fredoka(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        bodyLarge: GoogleFonts.fredoka(fontSize: 16, color: AppColors.textDark),
        bodyMedium: GoogleFonts.fredoka(
          fontSize: 14,
          color: AppColors.textDark.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
