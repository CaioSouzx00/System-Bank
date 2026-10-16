import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import '../theme/app_theme_extension.dart';
import 'bank_button.dart';

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final bankTheme = context.bankTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: bankTheme.primaryBrand.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 38,
                color: bankTheme.primaryBrand,
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppDimensions.xl),
              BankButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: BankButtonVariant.secondary,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
