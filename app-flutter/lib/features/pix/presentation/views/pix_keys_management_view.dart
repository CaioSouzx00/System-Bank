import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/haptic_feedback_utils.dart';
import '../../../../core/widgets/bank_button.dart';
import '../../../../core/widgets/bank_card.dart';
import '../../../../core/widgets/bank_shimmer.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../routes/app_routes.dart';
import '../data/models/pix_key.dart';
import '../providers/pix_provider.dart';

class PixKeysManagementView extends ConsumerWidget {
  const PixKeysManagementView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bankTheme = context.bankTheme;
    final keysAsync = ref.watch(pixKeysNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Chaves Pix'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: ResponsiveMaxContentWidth(
        maxWidth: 700,
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(pixKeysNotifierProvider.notifier).fetchKeys();
          },
          child: keysAsync.when(
            loading: () => ListView(
              padding: AppDimensions.screenPadding,
              children: const [
                BankShimmerCard(height: 90),
                SizedBox(height: 12),
                BankShimmerCard(height: 90),
              ],
            ),
            error: (err, _) => EmptyStateView(
              icon: Icons.error_outline_rounded,
              title: 'Erro ao carregar chaves',
              subtitle: err.toString(),
              actionLabel: 'Tentar Novamente',
              onAction: () => ref.read(pixKeysNotifierProvider.notifier).fetchKeys(),
            ),
            data: (keys) {
              if (keys.isEmpty) {
                return EmptyStateView(
                  icon: Icons.vpn_key_outlined,
                  title: 'Nenhuma chave cadastrada',
                  subtitle: 'Cadastre seu CPF, celular, e-mail ou crie uma chave aleatória.',
                  actionLabel: 'Registrar Chave',
                  onAction: () => context.push(AppRoutes.pixRegisterKey),
                );
              }

              return ListView(
                padding: AppDimensions.screenPadding,
                children: [
                  Text(
                    'Chaves cadastradas (${keys.length}/5)',
                    style: AppTypography.titleSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...keys.map((key) => _PixKeyCard(keyItem: key)),

                  const SizedBox(height: 24),

                  BankButton(
                    label: 'Registrar Nova Chave',
                    icon: Icons.add_rounded,
                    variant: BankButtonVariant.outline,
                    onPressed: () => context.push(AppRoutes.pixRegisterKey),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PixKeyCard extends ConsumerWidget {
  final PixKey keyItem;

  const _PixKeyCard({required this.keyItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bankTheme = context.bankTheme;

    IconData icon;
    switch (keyItem.keyType) {
      case PixKeyType.cpf:
        icon = Icons.badge_outlined;
        break;
      case PixKeyType.email:
        icon = Icons.mail_outline_rounded;
        break;
      case PixKeyType.phone:
        icon = Icons.phone_android_rounded;
        break;
      case PixKeyType.random:
        icon = Icons.vpn_key_rounded;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BankCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bankTheme.primaryBrand.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: bankTheme.primaryBrand),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    keyItem.keyType.label,
                    style: AppTypography.labelSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    keyItem.keyValue,
                    style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 20),
              tooltip: 'Copiar chave',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: keyItem.keyValue));
                HapticFeedbackUtils.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chave copiada para a área de transferência!'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.errorRed),
              tooltip: 'Excluir chave',
              onPressed: () => _confirmDelete(context, ref, keyItem),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, PixKey keyItem) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Chave Pix?'),
        content: Text('Tem certeza que deseja excluir a chave ${keyItem.keyValue}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref
                  .read(pixKeysNotifierProvider.notifier)
                  .removeKey(keyItem.id);
              if (success) {
                HapticFeedbackUtils.successFeedback();
              }
            },
            child: const Text('Excluir', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }
}
