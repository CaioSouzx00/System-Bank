import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../../core/widgets/bank_status_badge.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../routes/app_routes.dart';
import '../providers/accounts_provider.dart';

class AccountsListView extends ConsumerWidget {
  const AccountsListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bankTheme = context.bankTheme;
    final accountsAsync = ref.watch(accountsListNotifierProvider);
    final selectedAccount = ref.watch(selectedAccountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Contas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Nova Conta',
            onPressed: () {
              HapticFeedbackUtils.lightImpact();
              context.push(AppRoutes.createAccount);
            },
          ),
        ],
      ),
      body: ResponsiveMaxContentWidth(
        maxWidth: 800,
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(accountsListNotifierProvider.notifier).fetchAccounts();
          },
          child: accountsAsync.when(
            loading: () => ListView(
              padding: AppDimensions.screenPadding,
              children: const [
                BankShimmerCard(height: 140),
                SizedBox(height: 16),
                BankShimmerCard(height: 140),
              ],
            ),
            error: (err, _) => EmptyStateView(
              icon: Icons.error_outline_rounded,
              title: 'Erro ao carregar contas',
              subtitle: err.toString(),
              actionLabel: 'Tentar Novamente',
              onAction: () => ref.read(accountsListNotifierProvider.notifier).fetchAccounts(),
            ),
            data: (accounts) {
              if (accounts.isEmpty) {
                return EmptyStateView(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Nenhuma conta encontrada',
                  subtitle: 'Abra sua primeira conta no System-Bank para começar.',
                  actionLabel: 'Criar Conta',
                  onAction: () => context.push(AppRoutes.createAccount),
                );
              }

              return ListView.separated(
                padding: AppDimensions.screenPadding,
                itemCount: accounts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  final isSelected = selectedAccount?.id == account.id;

                  return BankCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? bankTheme.primaryBrand.withOpacity(0.12)
                                        : bankTheme.badgeBackground,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.account_balance_rounded,
                                    size: 22,
                                    color: isSelected ? bankTheme.primaryBrand : AppColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Conta Corrente',
                                      style: AppTypography.titleSmall,
                                    ),
                                    Text(
                                      account.formattedAccount,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            BankStatusBadge(status: account.status.value),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Saldo Disponível',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.format(account.balance),
                                  style: AppTypography.monetaryValue(
                                    fontSize: 22,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton.outlined(
                                  icon: const Icon(Icons.calculate_outlined, size: 20),
                                  tooltip: 'Simulação de Juros',
                                  onPressed: () {
                                    HapticFeedbackUtils.selectionClick();
                                    context.push('${AppRoutes.interestSimulation}?accountId=${account.id}');
                                  },
                                ),
                                const SizedBox(width: 8),
                                if (!isSelected)
                                  BankButton(
                                    label: 'Selecionar',
                                    isFullWidth: false,
                                    height: 38,
                                    variant: BankButtonVariant.secondary,
                                    onPressed: () {
                                      ref.read(selectedAccountProvider.notifier).state = account;
                                      HapticFeedbackUtils.successFeedback();
                                    },
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: bankTheme.primaryBrand.withOpacity(0.1),
                                      borderRadius: AppDimensions.borderRadiusPill,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle_rounded, size: 16, color: bankTheme.primaryBrand),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Ativa',
                                          style: AppTypography.labelSmall.copyWith(
                                            color: bankTheme.primaryBrand,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
