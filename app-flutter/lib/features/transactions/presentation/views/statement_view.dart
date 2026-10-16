import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/haptic_feedback_utils.dart';
import '../../../../core/widgets/bank_bottom_sheet.dart';
import '../../../../core/widgets/bank_button.dart';
import '../../../../core/widgets/bank_card.dart';
import '../../../../core/widgets/bank_shimmer.dart';
import '../../../../core/widgets/bank_status_badge.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../data/models/statement_query.dart';
import '../data/models/transaction_model.dart';
import '../providers/transactions_provider.dart';

class StatementView extends ConsumerStatefulWidget {
  const StatementView({super.key});

  @override
  ConsumerState<StatementView> createState() => _StatementViewState();
}

class _StatementViewState extends ConsumerState<StatementView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onPeriodChanged(StatementPeriod period) {
    HapticFeedbackUtils.selectionClick();
    final now = DateTime.now();
    DateTime from;

    switch (period) {
      case StatementPeriod.today:
        from = DateTime(now.year, now.month, now.day);
        break;
      case StatementPeriod.days7:
        from = now.subtract(const Duration(days: 7));
        break;
      case StatementPeriod.days30:
        from = now.subtract(const Duration(days: 30));
        break;
      case StatementPeriod.days90:
        from = now.subtract(const Duration(days: 90));
        break;
      case StatementPeriod.custom:
        _selectCustomDateRange();
        return;
    }

    final currentFilter = ref.read(statementFilterProvider);
    ref.read(statementFilterProvider.notifier).state = currentFilter.copyWith(
      period: period,
      fromDate: from,
      toDate: now,
    );

    ref.read(statementNotifierProvider.notifier).fetchStatement();
  }

  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 14)),
        end: DateTime.now(),
      ),
    );

    if (picked != null) {
      final currentFilter = ref.read(statementFilterProvider);
      ref.read(statementFilterProvider.notifier).state = currentFilter.copyWith(
        period: StatementPeriod.custom,
        fromDate: picked.start,
        toDate: picked.end,
      );
      ref.read(statementNotifierProvider.notifier).fetchStatement();
    }
  }

  void _showExportOptions() {
    HapticFeedbackUtils.mediumImpact();
    showBankBottomSheet(
      context: context,
      title: 'Exportar Extrato Bancário',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Selecione o formato para conciliação ou declaração fiscal:',
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 18),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusMd),
            leading: const Icon(Icons.code_rounded, color: AppColors.infoBlue),
            title: const Text('Exportar em JSON'),
            subtitle: const Text('Formato estruturado para integrações via API'),
            trailing: const Icon(Icons.download_rounded),
            onTap: () async {
              Navigator.of(context).pop();
              HapticFeedbackUtils.successFeedback();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Extrato em JSON gerado e copiado!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const Divider(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusMd),
            leading: const Icon(Icons.description_rounded, color: AppColors.secondaryGreen),
            title: const Text('Exportar em OFX (Open Financial Exchange)'),
            subtitle: const Text('Padrão para importação em ERPs e contabilidade'),
            trailing: const Icon(Icons.share_rounded),
            onTap: () async {
              Navigator.of(context).pop();
              final ofxContent = await ref.read(statementNotifierProvider.notifier).exportOfx();
              Share.share(ofxContent, subject: 'Extrato System-Bank OFX');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bankTheme = context.bankTheme;
    final statementAsync = ref.watch(statementNotifierProvider);
    final currentFilter = ref.watch(statementFilterProvider);
    final selectedAccount = ref.watch(selectedAccountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Extrato'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Exportar Extrato (JSON/OFX)',
            onPressed: _showExportOptions,
          ),
        ],
      ),
      body: ResponsiveMaxContentWidth(
        maxWidth: 800,
        child: Column(
          children: [
            // Period Filter Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: StatementPeriod.values.map((period) {
                    final isSelected = currentFilter.period == period;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(period.label),
                        selected: isSelected,
                        selectedColor: bankTheme.primaryBrand,
                        labelStyle: AppTypography.labelSmall.copyWith(
                          color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        onSelected: (_) => _onPeriodChanged(period),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Buscar por valor, tipo ou descrição...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // Main List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(statementNotifierProvider.notifier).fetchStatement();
                },
                child: statementAsync.when(
                  loading: () => ListView(
                    padding: AppDimensions.screenPadding,
                    children: const [
                      BankShimmerListTile(),
                      BankShimmerListTile(),
                      BankShimmerListTile(),
                      BankShimmerListTile(),
                    ],
                  ),
                  error: (err, _) => EmptyStateView(
                    icon: Icons.error_outline_rounded,
                    title: 'Falha ao obter extrato',
                    subtitle: err.toString(),
                    actionLabel: 'Tentar Novamente',
                    onAction: () => ref.read(statementNotifierProvider.notifier).fetchStatement(),
                  ),
                  data: (transactions) {
                    final filtered = transactions.where((tx) {
                      if (_searchQuery.isEmpty) return true;
                      final type = tx.type.label.toLowerCase();
                      final amountStr = tx.amount.toString();
                      final formatted = CurrencyFormatter.format(tx.amount).toLowerCase();
                      return type.contains(_searchQuery) ||
                          amountStr.contains(_searchQuery) ||
                          formatted.contains(_searchQuery);
                    }).toList();

                    if (filtered.isEmpty) {
                      return EmptyStateView(
                        icon: Icons.receipt_long_outlined,
                        title: 'Nenhum lançamento no período',
                        subtitle: 'Tente alterar o período selecionado ou faça uma nova movimentação.',
                      );
                    }

                    // Group by Day
                    final Map<String, List<TransactionModel>> grouped = {};
                    for (var tx in filtered) {
                      final header = DateFormatter.groupHeaderDate(tx.createdAt);
                      grouped.putIfAbsent(header, () => []).add(tx);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: grouped.keys.length,
                      itemBuilder: (context, groupIndex) {
                        final dateHeader = grouped.keys.elementAt(groupIndex);
                        final items = grouped[dateHeader]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                              child: Text(
                                dateHeader,
                                style: AppTypography.titleSmall.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            BankCard(
                              padding: EdgeInsets.zero,
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: items.length,
                                separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
                                itemBuilder: (context, index) {
                                  final tx = items[index];
                                  final isIncome = tx.type.isIncome;

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    leading: CircleAvatar(
                                      backgroundColor: isIncome
                                          ? AppColors.accentGreenLight
                                          : bankTheme.badgeBackground,
                                      child: Icon(
                                        isIncome
                                            ? Icons.south_west_rounded
                                            : Icons.north_east_rounded,
                                        size: 18,
                                        color: isIncome
                                            ? AppColors.secondaryGreen
                                            : bankTheme.primaryBrand,
                                      ),
                                    ),
                                    title: Text(tx.type.label, style: AppTypography.titleSmall),
                                    subtitle: Text(
                                      DateFormatter.formatTime(tx.createdAt),
                                      style: AppTypography.bodySmall.copyWith(color: Colors.grey),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${isIncome ? '+' : '-'} ${CurrencyFormatter.format(tx.amount)}',
                                          style: AppTypography.monetaryValue(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: isIncome
                                                ? AppColors.secondaryGreen
                                                : Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        BankStatusBadge(status: tx.status.value, isAnimated: false),
                                      ],
                                    ),
                                    onTap: () {
                                      HapticFeedbackUtils.selectionClick();
                                      _showTransactionDetails(context, tx);
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, TransactionModel tx) {
    showBankBottomSheet(
      context: context,
      title: 'Detalhes da Transação',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              '${tx.type.isIncome ? '+' : '-'} ${CurrencyFormatter.format(tx.amount)}',
              style: AppTypography.monetaryValue(
                fontSize: 32,
                color: tx.type.isIncome ? AppColors.secondaryGreen : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: BankStatusBadge(status: tx.status.value)),
          const SizedBox(height: 24),
          _detailRow('Tipo', tx.type.label),
          _detailRow('Data/Hora', DateFormatter.formatDateTime(tx.createdAt)),
          if (tx.processedAt != null)
            _detailRow('Liquidação', DateFormatter.formatDateTime(tx.processedAt!)),
          _detailRow('Correlation ID', tx.correlationId, isMono: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isMono = false}) {
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
                  : AppTypography.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}
