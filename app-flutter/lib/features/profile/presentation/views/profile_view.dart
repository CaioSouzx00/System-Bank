import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/haptic_feedback_utils.dart';
import '../../../../core/widgets/bank_button.dart';
import '../../../../core/widgets/bank_card.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../routes/app_routes.dart';
import '../../../auth/domain/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bankTheme = context.bankTheme;
    final authState = ref.watch(authNotifierProvider);
    final user = authState.currentUser;
    final role = authState.currentRole;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: ResponsiveMaxContentWidth(
        maxWidth: 700,
        child: SingleChildScrollView(
          padding: AppDimensions.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Avatar Card
              BankCard(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: bankTheme.primaryBrand.withOpacity(0.12),
                      child: Text(
                        (user?.name ?? 'U')[0].toUpperCase(),
                        style: AppTypography.displayMedium.copyWith(
                          color: bankTheme.primaryBrand,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Usuário',
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            style: AppTypography.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: role.isStaff
                                  ? AppColors.warningOrangeLight
                                  : bankTheme.badgeBackground,
                              borderRadius: AppDimensions.borderRadiusPill,
                            ),
                            child: Text(
                              'Perfil: ${role.label}',
                              style: AppTypography.labelSmall.copyWith(
                                color: role.isStaff
                                    ? const Color(0xFFB45309)
                                    : AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Switch Demo Role Section (For seamless testing of all 3 roles!)
              Text(
                'Alternar Perfil de Acesso (Demonstração)',
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              BankCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: UserRole.values.map((r) {
                    final isCurrent = role == r;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        r == UserRole.admin
                            ? Icons.admin_panel_settings_outlined
                            : r == UserRole.operator
                                ? Icons.support_agent_rounded
                                : Icons.person_outline_rounded,
                        color: isCurrent ? bankTheme.primaryBrand : Colors.grey,
                      ),
                      title: Text(r.label, style: AppTypography.titleSmall),
                      subtitle: Text(
                        r == UserRole.admin
                            ? 'Acesso total: Contas, Ledger, Reconciliação e Bloqueios'
                            : r == UserRole.operator
                                ? 'Acesso operacional: Métricas e triggers de batch jobs'
                                : 'Acesso correntista: PIX, transferências e extrato',
                        style: AppTypography.bodySmall.copyWith(color: Colors.grey),
                      ),
                      trailing: isCurrent
                          ? Icon(Icons.check_circle_rounded, color: bankTheme.primaryBrand)
                          : null,
                      onTap: () {
                        HapticFeedbackUtils.selectionClick();
                        ref.read(authNotifierProvider.notifier).switchRole(r);
                      },
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Operational Section Shortcut
              if (role.isStaff) ...[
                BankCard(
                  onTap: () => context.push(AppRoutes.reconciliation),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.assessment_outlined, color: AppColors.primaryPurple, size: 26),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Painel de Reconciliação COBOL', style: AppTypography.titleSmall),
                            Text('Métricas e auditoria do double-entry ledger', style: AppTypography.bodySmall.copyWith(color: Colors.grey)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Settings Option
              BankCard(
                onTap: () => context.push(AppRoutes.settings),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded, size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text('Configurações do Aplicativo', style: AppTypography.titleSmall),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Logout Button
              BankButton(
                label: 'Sair da Conta',
                icon: Icons.logout_rounded,
                variant: BankButtonVariant.danger,
                onPressed: () => _confirmLogout(context, ref),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desconectar?'),
        content: const Text('Deseja realmente sair da sua conta do System-Bank?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              HapticFeedbackUtils.selectionClick();
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            child: const Text('Sair', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }
}
