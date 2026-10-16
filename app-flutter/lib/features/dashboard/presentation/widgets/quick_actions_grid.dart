import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/haptic_feedback_utils.dart';
import '../../../../routes/app_routes.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final bankTheme = context.bankTheme;

    final actions = [
      {
        'icon': Icons.bolt_rounded,
        'label': 'Área Pix',
        'route': AppRoutes.pix,
      },
      {
        'icon': Icons.arrow_outward_rounded,
        'label': 'Transferir',
        'route': AppRoutes.newTransaction,
      },
      {
        'icon': Icons.arrow_downward_rounded,
        'label': 'Depositar',
        'route': '${AppRoutes.newTransaction}?type=CREDIT',
      },
      {
        'icon': Icons.receipt_long_rounded,
        'label': 'Extrato',
        'route': AppRoutes.statement,
      },
      {
        'icon': Icons.calculate_outlined,
        'label': 'Simular',
        'route': AppRoutes.interestSimulation,
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'label': 'Contas',
        'route': AppRoutes.accounts,
      },
    ];

    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = actions[index];

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: bankTheme.badgeBackground,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    HapticFeedbackUtils.selectionClick();
                    context.push(item['route'] as String);
                  },
                  child: SizedBox(
                    width: 58,
                    height: 58,
                    child: Center(
                      child: Icon(
                        item['icon'] as IconData,
                        size: 26,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['label'] as String,
                textAlign: TextAlign.center,
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
