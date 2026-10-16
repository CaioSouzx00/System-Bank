import 'package:flutter/material.dart';

abstract class AppColors {
  // Brand Colors
  static const Color primaryPurple = Color(0xFF820AD1);
  static const Color primaryDark = Color(0xFF1A1A2E);
  static const Color primaryGradientStart = Color(0xFF820AD1);
  static const Color primaryGradientEnd = Color(0xFF5A0099);

  // Accent & Semantic Colors
  static const Color secondaryGreen = Color(0xFF00D09C);
  static const Color accentGreenLight = Color(0xFFE6FBF5);
  static const Color errorRed = Color(0xFFFF3B30);
  static const Color errorRedLight = Color(0xFFFFEEEE);
  static const Color warningOrange = Color(0xFFFF9500);
  static const Color warningOrangeLight = Color(0xFFFFF6E5);
  static const Color infoBlue = Color(0xFF0A84FF);
  static const Color infoBlueLight = Color(0xFFEBF5FF);

  // Light Palette
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F3F5);
  static const Color borderLight = Color(0xFFE9ECEF);
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textMutedLight = Color(0xFF9CA3AF);

  // Dark Palette
  static const Color backgroundDark = Color(0xFF12121C);
  static const Color surfaceDark = Color(0xFF1E1E2E);
  static const Color surfaceVariantDark = Color(0xFF28283E);
  static const Color borderDark = Color(0xFF32324D);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textMutedDark = Color(0xFF6B7280);

  // Status Badges
  static const Color statusPending = Color(0xFFFF9500);
  static const Color statusProcessed = Color(0xFF00D09C);
  static const Color statusFailed = Color(0xFFFF3B30);
  static const Color statusReversed = Color(0xFF8E8E93);
}
