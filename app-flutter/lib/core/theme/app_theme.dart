import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import 'app_theme_extension.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primaryPurple,
      onPrimary: Colors.white,
      secondary: AppColors.secondaryGreen,
      onSecondary: Colors.white,
      error: AppColors.errorRed,
      onError: Colors.white,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      surfaceContainerHighest: AppColors.surfaceVariantLight,
      outline: AppColors.borderLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      fontFamily: GoogleFonts.inter().fontFamily,
      extensions: const [BankThemeExtension.light],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.titleLarge.copyWith(color: AppColors.textPrimaryLight),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
      ),
      cardTheme: CardTheme(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLg,
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusMd),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryPurple,
          textStyle: AppTypography.labelLarge,
          side: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusMd),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMutedLight),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryPurple,
        unselectedItemColor: AppColors.textMutedLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: const Color(0xFF9D34DA),
      onPrimary: Colors.white,
      secondary: AppColors.secondaryGreen,
      onSecondary: Colors.white,
      error: AppColors.errorRed,
      onError: Colors.white,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      surfaceContainerHighest: AppColors.surfaceVariantDark,
      outline: AppColors.borderDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      fontFamily: GoogleFonts.inter().fontFamily,
      extensions: const [BankThemeExtension.dark],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.titleLarge.copyWith(color: AppColors.textPrimaryDark),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
      ),
      cardTheme: CardTheme(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLg,
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9D34DA),
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusMd),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFB968E8),
          textStyle: AppTypography.labelLarge,
          side: const BorderSide(color: Color(0xFFB968E8), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusMd),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMd,
          borderSide: const BorderSide(color: Color(0xFF9D34DA), width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryDark),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMutedDark),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: Color(0xFF9D34DA),
        unselectedItemColor: AppColors.textMutedDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
