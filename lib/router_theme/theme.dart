import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Color Palette từ Figma Design
class AppColors {
  // Primary Colors - Red Accent
  static const Color primary = Color(0xFFEF5350); // Red Accent
  static const Color primaryLight = Color(0xFFFFCDD2); // Red 100
  static const Color primaryDark = Color(0xFFC62828); // Red 800
  
  // Gradient Colors
  static const Color gradientStart = Color(0xFFEF5350); // Red 400
  static const Color gradientEnd = Color(0xFFC62828); // Red 700
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Neutral Colors
  static const Color background = Color(0xFFF5F5F5); // Grey 100
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFBDBDBD);
  
  // Online/Offline Status
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF9E9E9E);
}

final appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.primaryDark,
    surface: AppColors.surface,
    error: AppColors.error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.textPrimary,
    onError: Colors.white,
    brightness: Brightness.light,
  ),
  textTheme: GoogleFonts.interTextTheme().copyWith(
    displayLarge: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      color: AppColors.textPrimary,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      color: AppColors.textPrimary,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      color: AppColors.textSecondary,
    ),
  ),
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.background,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surface,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary, width: 2),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.error, width: 1),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
  dividerTheme: DividerThemeData(
    color: AppColors.divider,
    thickness: 1,
    space: 1,
  ),
);
