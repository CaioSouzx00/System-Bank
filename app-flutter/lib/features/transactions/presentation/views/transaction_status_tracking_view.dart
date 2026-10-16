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
import '../../../../core/widgets/bank_button.dart';
import '../../../../core/widgets/bank_card.dart';
import '../../../../core/widgets/bank_status_badge.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../routes/app_routes.dart';
import '../data/models/transaction_model.dart';
import '../providers/transactions_provider.dart';

class TransactionStatusTrackingView extends ConsumerStatefulWidget {
  final TransactionModel initialTransaction;

  const TransactionStatusTrackingView({
    super.key,
    required this.initialTransaction,
  });

  @override
  ConsumerState<TransactionStatusTrackingView> createState() =>
      _TransactionStatusTrackingViewState();
}

class _TransactionStatusTrackingViewState
    extends ConsumerState<TransactionStatusTrackingView> {
  late TransactionModel _currentTransaction;

  @override
  void initState() {
    super.initState();
    _currentTransaction = widget.initialTransaction;
    _startStatusTracking();
  }

  void _startStatusTracking() {
    final repo = ref.read(transactionsRepositoryProvider);
    repo.trackTransactionStatus(widget.initialTransaction).listen((updated) {
      if (mounted) {
        setState(() {
          _currentTransaction = updated;
        });

        if (updated.status == TransactionStatus.processed) {
          HapticFeedbackUtils.successFeedback();
          // Atualiza lista do extrato e contas em background
          ref.read(statementNotifierProvider.notifier).fetchStatement();
        } else if (updated.status == TransactionStatus.failed) {
          HapticFeedbackUtils.errorFeedback();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bankTheme = context.bankTheme;
    final isPending = _currentTransaction.status.isPending;
    final isProcessed = _currentTransaction.status.isProcessed;
    final isFailed = _currentTransaction.status.isFailed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status da Transação'),
        automaticallyImplyLeading: !isPending,
      ),
      body: ResponsiveMaxContentWidth(
        maxWidth: 600,
        child: SingleChildScrollView(
          padding: AppDimensions.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Status Visual Icon
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: isProcessed
                        ? AppColors.accentGreenLight
                        : isFailed
                            ? AppColors.errorRedLight
                            : AppColors.warningOrangeLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isPending
                        ? SizedBox(
                            width: 44,
                            height: 44,
                            child: CircularProgressIndicator(
                              strokeWidth: 3.5,
                              color: bankTheme.statusPending,
                            ),
                          )
                        : Icon(
                            isProcessed
                                ? Icons.check_circle_rounded
                                : Icons.error_rounded,
                            size: 54,
                            color: isProcessed
                                ? AppColors.secondaryGreen
                                : AppColors.errorRed,
                          ),
                  ),
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 24),

              // Title & Description
              Text(
                isPending
                    ? 'Processando no Ledger...'
                    : isProcessed
                        ? 'Transação Processada!'
                        : 'Transação Falhou',
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 8),

              Text(
                isPending
                    ? 'A requisição foi aceita (202 Accepted) e aguarda reconciliação assíncrona nas filas do RabbitMQ.'
                    : isProcessed
                        ? 'Partidas dobradas lançadas no double-entry ledger com sucesso.'
                        : (_currentTransaction.failureReason ?? 'Falha ao validar saldo ou limites contábeis.'),
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                ),
              ),

              const SizedBox(height: 28),

              // Card de Resumo
              BankCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        CurrencyFormatter.format(_currentTransaction.amount),
                        style: AppTypography.monetaryValue(
                          fontSize: 28,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: BankStatusBadge(status: _currentTransaction.status.value),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),

                    _infoRow('Operação', _currentTransaction.type.label),
                    _infoRow('Conta', _currentTransaction.accountId),
                    if (_currentTransaction.destinationAccountId != null)
                      _infoRow('Conta Destino', _currentTransaction.destinationAccountId!),
                    _infoRow('Data Envio', DateFormatter.formatDateTime(_currentTransaction.createdAt)),
                    if (_currentTransaction.processedAt != null)
                      _infoRow('Data Liquidação', DateFormatter.formatDateTime(_currentTransaction.processedAt!)),
                    _infoRow('Correlation ID', _currentTransaction.correlationId, isMono: true),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              if (isProcessed)
                BankButton(
                  label: 'Voltar ao Início',
                  icon: Icons.home_rounded,
                  onPressed: () => context.go(AppRoutes.dashboard),
                )
              else if (isFailed)
                BankButton(
                  label: 'Tentar Novamente',
                  icon: Icons.refresh_rounded,
                  onPressed: () => context.pop(),
                )
              else
                BankButton(
                  label: 'Acompanhar em Segundo Plano',
                  variant: BankButtonVariant.secondary,
                  onPressed: () => context.go(AppRoutes.dashboard),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isMono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
                  : AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
