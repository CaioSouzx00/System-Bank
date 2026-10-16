import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import '../theme/app_theme_extension.dart';
import '../utils/haptic_feedback_utils.dart';

enum BankCardType {
  surface,
  gradient,
  outlined,
}

class BankCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final BankCardType type;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;

  const BankCard({
    super.key,
    required this.child,
    this.padding = AppDimensions.cardPadding,
    this.onTap,
    this.type = BankCardType.surface,
    this.borderRadius,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final bankTheme = context.bankTheme;
    final radius = borderRadius ?? AppDimensions.borderRadiusLg;

    Decoration decoration;
    switch (type) {
      case BankCardType.gradient:
        decoration = BoxDecoration(
          gradient: bankTheme.primaryCardGradient,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: bankTheme.primaryBrand.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        );
        break;
      case BankCardType.outlined:
        decoration = BoxDecoration(
          color: Colors.transparent,
          borderRadius: radius,
          border: Border.all(color: bankTheme.cardBorder, width: 1.5),
        );
        break;
      case BankCardType.surface:
      default:
        decoration = BoxDecoration(
          color: bankTheme.cardBackground,
          borderRadius: radius,
          border: Border.all(color: bankTheme.cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        );
        break;
    }

    Widget cardContent = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedbackUtils.selectionClick();
            onTap!();
          },
          borderRadius: radius,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
