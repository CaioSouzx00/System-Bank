import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class BankThemeExtension extends ThemeExtension<BankThemeExtension> {
  final Color primaryBrand;
  final Color secondarySuccess;
  final Color cardBackground;
  final Color cardBorder;
  final LinearGradient primaryCardGradient;
  final Color statusPending;
  final Color statusProcessed;
  final Color statusFailed;
  final Color shimmerBase;
  final Color shimmerHighlight;
  final Color badgeBackground;
  final Color inputFill;

  const BankThemeExtension({
    required this.primaryBrand,
    required this.secondarySuccess,
    required this.cardBackground,
    required this.cardBorder,
    required this.primaryCardGradient,
    required this.statusPending,
    required this.statusProcessed,
    required this.statusFailed,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.badgeBackground,
    required this.inputFill,
  });

  static const light = BankThemeExtension(
    primaryBrand: AppColors.primaryPurple,
    secondarySuccess: AppColors.secondaryGreen,
    cardBackground: AppColors.surfaceLight,
    cardBorder: AppColors.borderLight,
    primaryCardGradient: LinearGradient(
      colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    statusPending: AppColors.statusPending,
    statusProcessed: AppColors.statusProcessed,
    statusFailed: AppColors.statusFailed,
    shimmerBase: Color(0xFFE5E7EB),
    shimmerHighlight: Color(0xFFF3F4F6),
    badgeBackground: Color(0xFFF3F4F6),
    inputFill: Color(0xFFF8F9FA),
  );

  static const dark = BankThemeExtension(
    primaryBrand: Color(0xFF9D34DA),
    secondarySuccess: AppColors.secondaryGreen,
    cardBackground: AppColors.surfaceDark,
    cardBorder: AppColors.borderDark,
    primaryCardGradient: LinearGradient(
      colors: [Color(0xFF820AD1), Color(0xFF3B0066)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    statusPending: AppColors.statusPending,
    statusProcessed: AppColors.statusProcessed,
    statusFailed: AppColors.statusFailed,
    shimmerBase: Color(0xFF28283E),
    shimmerHighlight: Color(0xFF363654),
    badgeBackground: Color(0xFF28283E),
    inputFill: Color(0xFF1E1E2E),
  );

  @override
  ThemeExtension<BankThemeExtension> copyWith({
    Color? primaryBrand,
    Color? secondarySuccess,
    Color? cardBackground,
    Color? cardBorder,
    LinearGradient? primaryCardGradient,
    Color? statusPending,
    Color? statusProcessed,
    Color? statusFailed,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? badgeBackground,
    Color? inputFill,
  }) {
    return BankThemeExtension(
      primaryBrand: primaryBrand ?? this.primaryBrand,
      secondarySuccess: secondarySuccess ?? this.secondarySuccess,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      primaryCardGradient: primaryCardGradient ?? this.primaryCardGradient,
      statusPending: statusPending ?? this.statusPending,
      statusProcessed: statusProcessed ?? this.statusProcessed,
      statusFailed: statusFailed ?? this.statusFailed,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      badgeBackground: badgeBackground ?? this.badgeBackground,
      inputFill: inputFill ?? this.inputFill,
    );
  }

  @override
  ThemeExtension<BankThemeExtension> lerp(
    covariant ThemeExtension<BankThemeExtension>? other,
    double t,
  ) {
    if (other is! BankThemeExtension) return this;
    return BankThemeExtension(
      primaryBrand: Color.lerp(primaryBrand, other.primaryBrand, t)!,
      secondarySuccess: Color.lerp(secondarySuccess, other.secondarySuccess, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      primaryCardGradient: LinearGradient.lerp(primaryCardGradient, other.primaryCardGradient, t)!,
      statusPending: Color.lerp(statusPending, other.statusPending, t)!,
      statusProcessed: Color.lerp(statusProcessed, other.statusProcessed, t)!,
      statusFailed: Color.lerp(statusFailed, other.statusFailed, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
      badgeBackground: Color.lerp(badgeBackground, other.badgeBackground, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
    );
  }
}

extension BankThemeContext on BuildContext {
  BankThemeExtension get bankTheme =>
      Theme.of(this).extension<BankThemeExtension>() ?? BankThemeExtension.light;
}
