import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/haptic_feedback_utils.dart';
import '../../../../core/widgets/bank_card.dart';
import '../../../../core/widgets/bank_status_badge.dart';
import '../../../accounts/data/models/bank_account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';

class BalanceCard extends ConsumerWidget {
  final BankAccount? account;
  final bool isLoading;

  const BalanceCard({
    super.key,
    required this.account,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bankTheme = context.bankTheme;
    final isHidden = ref.watch(hideBalanceProvider);

    return BankCard(
      type: BankCardType.gradient,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Account & Hide Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: AppDimensions.borderRadiusPill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_balance_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          account != null
                              ? 'Ag ${account!.agency} • C/C ${account!.accountNumber}'
                              : 'System-Bank Digital',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (account != null)
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: '${account!.agency} ${account!.accountNumber}'));
                        HapticFeedbackUtils.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dados da conta copiados!'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.copy_rounded, size: 15, color: Colors.white.withOpacity(0.8)),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: Icon(
                  isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () {
                  HapticFeedbackUtils.selectionClick();
                  ref.read(hideBalanceProvider.notifier).toggle();
                },
                tooltip: isHidden ? 'Mostrar saldo' : 'Ocultar saldo',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Balance Label
          Text(
            'Saldo disponível',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.75),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 6),

          // Monetary Value (Large, with Tabular Figures)
          if (isLoading)
            Container(
              width: 160,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(8),
              ),
            )
          else if (isHidden)
            Container(
              height: 36,
              alignment: Alignment.centerLeft,
              child: Text(
                '••••••••',
                style: AppTypography.displayMedium.copyWith(
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
            )
          else
            Text(
              CurrencyFormatter.format(account?.balance ?? 0.0),
              style: AppTypography.monetaryValue(
                fontSize: 32,
                color: Colors.white,
              ),
            ),

          const SizedBox(height: 18),

          // Bottom card row: Status and Rendimento tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (account != null)
                BankStatusBadge(status: account!.status.value)
              else
                const SizedBox.shrink(),
              Row(
                children: [
                  Icon(Icons.trending_up_rounded, size: 16, color: bankTheme.secondarySuccess),
                  const SizedBox(width: 4),
                  Text(
                    'Rendimento 100% CDI',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
