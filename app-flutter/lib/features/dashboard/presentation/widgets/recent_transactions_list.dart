import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/haptic_feedback_utils.dart';
import '../../../../core/widgets/bank_bottom_sheet.dart';
import '../../../../core/widgets/bank_card.dart';
import '../../../../core/widgets/bank_status_badge.dart';
import '../../../../routes/app_routes.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';

class RecentTransactionsList extends ConsumerWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(recentTransactionsProvider);
    final bankTheme = context.bankTheme;

    if (transactions.isEmpty) {
      return BankCard(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 36,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 8),
              Text(
                'Nenhuma transação recente',
                style: AppTypography.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Suas movimentações aparecerão aqui.',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        BankCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return _TransactionTile(tx: tx)
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 50 * index), duration: 300.ms);
            },
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type.isIncome;
    final bankTheme = context.bankTheme;

    IconData icon;
    Color iconColor;
    Color iconBg;

    switch (tx.type) {
      case TransactionType.credit:
        icon = Icons.south_west_rounded;
        iconColor = AppColors.secondaryGreen;
        iconBg = AppColors.accentGreenLight;
        break;
      case TransactionType.debit:
        icon = Icons.north_east_rounded;
        iconColor = bankTheme.primaryBrand;
        iconBg = bankTheme.primaryBrand.withOpacity(0.1);
        break;
      case TransactionType.transfer:
        icon = Icons.swap_horiz_rounded;
        iconColor = AppColors.infoBlue;
        iconBg = AppColors.infoBlueLight;
        break;
      case TransactionType.fee:
        icon = Icons.receipt_outlined;
        iconColor = AppColors.errorRed;
        iconBg = AppColors.errorRedLight;
        break;
    }

    return InkWell(
      onTap: () {
        HapticFeedbackUtils.selectionClick();
        _showTransactionDetailSheet(context, tx);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),

            // Description and Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.type.label,
                    style: AppTypography.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormatter.relativeDate(tx.createdAt),
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),

            // Value & Status Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'} ${CurrencyFormatter.format(tx.amount)}',
                  style: AppTypography.monetaryValue(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isIncome ? AppColors.secondaryGreen : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                BankStatusBadge(status: tx.status.value, isAnimated: false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetailSheet(BuildContext context, TransactionModel tx) {
    showBankBottomSheet(
      context: context,
      title: 'Comprovante de Transação',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              '${tx.type.isIncome ? '+' : '-'} ${CurrencyFormatter.format(tx.amount)}',
              style: AppTypography.monetaryValue(
                fontSize: 30,
                color: tx.type.isIncome ? AppColors.secondaryGreen : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: BankStatusBadge(status: tx.status.value)),
          const SizedBox(height: 24),
          _detailRow('Tipo', tx.type.label),
          _detailRow('Data e Hora', DateFormatter.formatDateTime(tx.createdAt)),
          _detailRow('Conta de Origem', tx.accountId),
          if (tx.destinationAccountId != null)
            _detailRow('Conta de Destino', tx.destinationAccountId!),
          _detailRow('ID de Correlação', tx.correlationId, isMono: true),
          if (tx.failureReason != null)
            _detailRow('Motivo da Falha', tx.failureReason!, isError: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isMono = false, bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: isMono
                  ? AppTypography.labelSmall.copyWith(fontFamily: 'monospace')
                  : isError
                      ? AppTypography.labelSmall.copyWith(color: AppColors.errorRed)
                      : AppTypography.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}
