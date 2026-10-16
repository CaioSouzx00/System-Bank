import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import '../theme/app_theme_extension.dart';
import '../utils/haptic_feedback_utils.dart';

enum BankButtonVariant {
  primary,
  secondary,
  outline,
  danger,
  ghost,
}

class BankButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final BankButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool isFullWidth;
  final double? height;

  const BankButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = BankButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = true,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final bankTheme = context.bankTheme;
    final isEnabled = onPressed != null && !isLoading;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case BankButtonVariant.primary:
        backgroundColor = bankTheme.primaryBrand;
        foregroundColor = Colors.white;
        break;
      case BankButtonVariant.secondary:
        backgroundColor = bankTheme.badgeBackground;
        foregroundColor = bankTheme.primaryBrand;
        break;
      case BankButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = bankTheme.primaryBrand;
        borderSide = BorderSide(color: bankTheme.primaryBrand, width: 1.5);
        break;
      case BankButtonVariant.danger:
        backgroundColor = AppColors.errorRed;
        foregroundColor = Colors.white;
        break;
      case BankButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = Theme.of(context).colorScheme.onSurface;
        break;
    }

    Widget content = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        : Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: foregroundColor),
                const SizedBox(width: AppDimensions.sm),
              ],
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: Material(
        color: isEnabled ? backgroundColor : backgroundColor.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusMd,
          side: borderSide,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled
              ? () {
                  HapticFeedbackUtils.lightImpact();
                  onPressed!();
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
