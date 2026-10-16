import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/haptic_feedback_utils.dart';
import '../../../../core/widgets/bank_card.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../routes/app_routes.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../auth/domain/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/recent_transactions_list.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bankTheme = context.bankTheme;
    final authState = ref.watch(authNotifierProvider);
    final user = authState.currentUser;
    final currentRole = authState.currentRole;
    final selectedAccount = ref.watch(selectedAccountProvider);
    final accountsAsync = ref.watch(accountsListNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: ResponsiveMaxContentWidth(
          maxWidth: 900,
          child: RefreshIndicator(
            onRefresh: () async {
              HapticFeedbackUtils.lightImpact();
              await Future.wait([
                ref.read(accountsListNotifierProvider.notifier).fetchAccounts(),
                ref.read(statementNotifierProvider.notifier).fetchStatement(),
              ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppDimensions.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Bar: User Greeting, Role Chip, Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: bankTheme.primaryBrand.withOpacity(0.12),
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              size: 24,
                              color: bankTheme.primaryBrand,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Olá, ${user?.name ?? 'Cliente'}',
                                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: currentRole.isStaff
                                      ? AppColors.warningOrangeLight
                                      : bankTheme.badgeBackground,
                                  borderRadius: AppDimensions.borderRadiusPill,
                                ),
                                child: Text(
                                  currentRole.label,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: currentRole.isStaff
                                        ? const Color(0xFFB45309)
                                        : AppColors.textSecondaryLight,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none_rounded),
                            tooltip: 'Notificações',
                            onPressed: () {
                              HapticFeedbackUtils.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Nenhuma nova notificação no momento.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined),
                            tooltip: 'Configurações',
                            onPressed: () {
                              HapticFeedbackUtils.selectionClick();
                              context.push(AppRoutes.settings);
                            },
                          ),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms),

                  const SizedBox(height: 20),

                  // Hero Balance Card
                  BalanceCard(
                    account: selectedAccount,
                    isLoading: accountsAsync.isLoading,
                  ).animate().fadeIn(duration: 400.ms).moveY(begin: 10, end: 0, duration: 400.ms),

                  const SizedBox(height: 24),

                  // Quick Actions Bar (Horizontal Scroll)
                  const QuickActionsGrid().animate().fadeIn(delay: 150.ms, duration: 400.ms),

                  // Operational Reconciliation Banner (Visible for OPERATOR & ADMIN)
                  if (currentRole.isStaff) ...[
                    const SizedBox(height: 20),
                    BankCard(
                      onTap: () {
                        HapticFeedbackUtils.selectionClick();
                        context.push(AppRoutes.reconciliation);
                      },
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.warningOrangeLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.tune_rounded, color: Color(0xFFB45309), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Painel de Reconciliação',
                                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: bankTheme.primaryBrand.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'STAFF',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: bankTheme.primaryBrand,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Auditoria double-entry e batch jobs COBOL em tempo real',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                  ],

                  const SizedBox(height: 24),

                  // Recent Transactions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Últimas transações',
                        style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedbackUtils.selectionClick();
                          context.push(AppRoutes.statement);
                        },
                        child: Text(
                          'Ver extrato',
                          style: AppTypography.labelLarge.copyWith(
                            color: bankTheme.primaryBrand,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Recent Transactions List
                  const RecentTransactionsList().animate().fadeIn(delay: 250.ms),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
