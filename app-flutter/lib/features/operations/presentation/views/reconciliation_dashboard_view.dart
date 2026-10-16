import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/haptic_feedback_utils.dart';
import '../../../../core/widgets/bank_button.dart';
import '../../../../core/widgets/bank_card.dart';
import '../../../../core/widgets/bank_shimmer.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../auth/domain/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../data/models/reconciliation_models.dart';
import '../providers/reconciliation_provider.dart';

class ReconciliationDashboardView extends ConsumerStatefulWidget {
  const ReconciliationDashboardView({super.key});

  @override
  ConsumerState<ReconciliationDashboardView> createState() =>
      _ReconciliationDashboardViewState();
}

class _ReconciliationDashboardViewState
    extends ConsumerState<ReconciliationDashboardView> {
  bool _isTriggering = false;

  Future<void> _handleTriggerBatch() async {
    HapticFeedbackUtils.mediumImpact();
    setState(() => _isTriggering = true);

    final success =
        await ref.read(reconciliationNotifierProvider.notifier).triggerJob();

    setState(() => _isTriggering = false);

    if (mounted) {
      if (success) {
        HapticFeedbackUtils.successFeedback();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job de reconciliação COBOL disparado com sucesso!'),
            backgroundColor: AppColors.secondaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankTheme = context.bankTheme;
    final authState = ref.watch(authNotifierProvider);
    final metricsAsync = ref.watch(reconciliationNotifierProvider);

    // Guard: Only OPERATOR or ADMIN
    if (!authState.currentRole.isStaff) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acesso Restrito')),
        body: Center(
          child: EmptyStateView(
            icon: Icons.lock_outline_rounded,
            title: 'Área Operacional Bloqueada',
            subtitle: 'Este painel é restrito aos perfis OPERATOR e ADMIN.',
            actionLabel: 'Voltar',
            onAction: () => context.pop(),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Operacional'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar Métricas',
            onPressed: () {
              ref.read(reconciliationNotifierProvider.notifier).fetchMetrics();
            },
          ),
        ],
      ),
      body: ResponsiveMaxContentWidth(
        maxWidth: 900,
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(reconciliationNotifierProvider.notifier).fetchMetrics();
          },
          child: metricsAsync.when(
            loading: () => ListView(
              padding: AppDimensions.screenPadding,
              children: const [
                BankShimmerCard(height: 120),
                SizedBox(height: 16),
                BankShimmerCard(height: 160),
                SizedBox(height: 16),
                BankShimmerCard(height: 160),
              ],
            ),
            error: (err, _) => EmptyStateView(
              icon: Icons.error_outline_rounded,
              title: 'Erro ao carregar métricas operacionais',
              subtitle: err.toString(),
              actionLabel: 'Tentar Novamente',
              onAction: () => ref.read(reconciliationNotifierProvider.notifier).fetchMetrics(),
            ),
            data: (data) => _buildDashboardContent(context, data),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, OperationalDashboardData data) {
    final bankTheme = context.bankTheme;
    final isHealthy = data.systemStatus.toUpperCase() == 'HEALTHY';

    return SingleChildScrollView(
      padding: AppDimensions.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // System Health Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isHealthy ? AppColors.accentGreenLight : AppColors.warningOrangeLight,
              borderRadius: AppDimensions.borderRadiusMd,
              border: Border.all(
                color: isHealthy ? AppColors.secondaryGreen : AppColors.warningOrange,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isHealthy ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                  color: isHealthy ? AppColors.secondaryGreen : AppColors.warningOrange,
                  size: 26,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status do Core Banking: ${data.systemStatus}',
                        style: AppTypography.titleSmall.copyWith(
                          color: isHealthy ? const Color(0xFF047857) : const Color(0xFFB45309),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Partidas dobradas, RabbitMQ e COBOL em conformidade.',
                        style: AppTypography.bodySmall.copyWith(
                          color: isHealthy ? const Color(0xFF065F46) : const Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Double-Entry Ledger Card
          Text(
            'Auditoria Contábil (Double-Entry Ledger)',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          BankCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.balance_rounded, size: 22, color: AppColors.infoBlue),
                        const SizedBox(width: 8),
                        Text(
                          'Equilíbrio Contábil (Débito = Crédito)',
                          style: AppTypography.titleSmall,
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: data.ledger.isBalanced
                            ? AppColors.accentGreenLight
                            : AppColors.errorRedLight,
                        borderRadius: AppDimensions.borderRadiusPill,
                      ),
                      child: Text(
                        data.ledger.isBalanced ? 'BALANCEADO' : 'DIVERGENTE',
                        style: AppTypography.labelSmall.copyWith(
                          color: data.ledger.isBalanced ? AppColors.secondaryGreen : AppColors.errorRed,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _metricCol('Total Débito', CurrencyFormatter.format(data.ledger.totalDebit)),
                    _metricCol('Total Crédito', CurrencyFormatter.format(data.ledger.totalCredit)),
                    _metricCol(
                      'Discrepância',
                      CurrencyFormatter.format(data.ledger.netDiscrepancy),
                      isHighlight: data.ledger.netDiscrepancy != 0.0,
                    ),
                  ],
                ),
                const Divider(height: 28),
                Text(
                  'Total de lançamentos contábeis: ${data.ledger.totalLedgerEntries}',
                  style: AppTypography.bodySmall.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Transactions and Accounts Metrics Grid
          Text(
            'Integridade Operacional',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: BankCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Transações', style: AppTypography.titleSmall),
                      const SizedBox(height: 10),
                      _rowKV('Total:', '${data.transactions.totalTransactions}'),
                      _rowKV('Processadas:', '${data.transactions.processedTransactions}'),
                      _rowKV('Pendentes:', '${data.transactions.pendingTransactions}'),
                      _rowKV('Falhas:', '${data.transactions.failedTransactions}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: BankCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Custódia de Contas', style: AppTypography.titleSmall),
                      const SizedBox(height: 10),
                      _rowKV('Total contas:', '${data.accounts.totalAccounts}'),
                      _rowKV('Ativas:', '${data.accounts.activeAccounts}'),
                      _rowKV('Bloqueadas:', '${data.accounts.blockedAccounts}'),
                      _rowKV('Saldo Total:', CurrencyFormatter.formatCompact(data.accounts.totalCustodyBalance)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // COBOL Batch Job Execution Section
          Text(
            'Processamento em Lote (COBOL Batch Engine)',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          BankCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Job: RECONCILIATION.cbl', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          'Última execução: ${data.batch.lastReconciliationStatus ?? 'SUCESSO'}',
                          style: AppTypography.bodySmall.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                    const Icon(Icons.terminal_rounded, size: 28, color: AppColors.primaryPurple),
                  ],
                ),
                const SizedBox(height: 18),
                _rowKV('Registros auditados hoje:', '${data.batch.reconciledToday}'),
                _rowKV('Divergências detectadas:', '${data.batch.divergentToday}'),
                const SizedBox(height: 20),
                BankButton(
                  label: 'Disparar Reconciliação COBOL Manual',
                  icon: Icons.play_arrow_rounded,
                  isLoading: _isTriggering,
                  onPressed: _handleTriggerBatch,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _metricCol(String title, String value, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.labelSmall.copyWith(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: isHighlight ? AppColors.errorRed : null,
          ),
        ),
      ],
    );
  }

  Widget _rowKV(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
          Text(v, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
