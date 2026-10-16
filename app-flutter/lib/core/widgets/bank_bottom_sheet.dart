import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import '../theme/app_theme_extension.dart';

Future<T?> showBankBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  bool isScrollControlled = true,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (context) => BankBottomSheetContainer(
      title: title,
      child: child,
    ),
  );
}

class BankBottomSheetContainer extends StatelessWidget {
  final String? title;
  final Widget child;

  const BankBottomSheetContainer({
    super.key,
    this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bankTheme = context.bankTheme;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Container(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      decoration: BoxDecoration(
        color: bankTheme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: AppDimensions.bottomSheetPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppDimensions.md),
                  decoration: BoxDecoration(
                    color: bankTheme.cardBorder,
                    borderRadius: AppDimensions.borderRadiusPill,
                  ),
                ),
              ),
              // Header Title if provided
              if (title != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title!, style: AppTypography.titleMedium),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.md),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}
