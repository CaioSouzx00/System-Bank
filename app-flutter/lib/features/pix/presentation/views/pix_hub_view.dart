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

class PixHubView extends ConsumerWidget {
  const PixHubView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bankTheme = context.bankTheme;

    final pixOptions = [
      {
        'title': 'Transferir via Pix',
        'subtitle': 'Envie dinheiro em segundos usando chave CPF, e-mail, celular ou aleatória',
        'icon': Icons.arrow_outward_rounded,
        'route': AppRoutes.pixSend,
        'badge': 'Instantâneo',
        'badgeColor': AppColors.secondaryGreen,
      },
      {
        'title': 'Cobrar / Receber com QR Code',
        'subtitle': 'Gere um código QR Pix dinâmico ou estático para receber pagamentos',
        'icon': Icons.qr_code_rounded,
        'route': AppRoutes.pixQr,
        'badge': 'QR Code',
        'badgeColor': bankTheme.primaryBrand,
      },
      {
        'title': 'Minhas Chaves Pix',
        'subtitle': 'Cadastre, visualize e gerencie suas chaves registradas no Banco Central',
        'icon': Icons.vpn_key_outlined,
        'route': AppRoutes.pixKeys,
        'badge': 'BACEN',
        'badgeColor': AppColors.infoBlue,
      },
      {
        'title': 'Pix Copia e Cola',
        'subtitle': 'Cole um código Pix EMV BR Code para pagar boletos ou contas instantâneas',
        'icon': Icons.content_paste_rounded,
        'route': AppRoutes.pixSend,
        'badge': 'Copia e Cola',
        'badgeColor': AppColors.warningOrange,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Área Pix'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: ResponsiveMaxContentWidth(
        maxWidth: 700,
        child: SingleChildScrollView(
          padding: AppDimensions.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pix Hero Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      bankTheme.primaryBrand.withOpacity(0.12),
                      bankTheme.secondarySuccess.withOpacity(0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppDimensions.borderRadiusLg,
                  border: Border.all(color: bankTheme.primaryBrand.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bankTheme.primaryBrand,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pix 24 horas por dia',
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Transferências gratuitas e liquidação imediata pelo System-Bank.',
                            style: AppTypography.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 24),

              Text(
                'Opções de Pagamento',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 12),

              ...pixOptions.map((opt) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BankCard(
                    onTap: () {
                      HapticFeedbackUtils.selectionClick();
                      context.push(opt['route'] as String);
                    },
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: bankTheme.badgeBackground,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(opt['icon'] as IconData, size: 24, color: bankTheme.primaryBrand),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    opt['title'] as String,
                                    style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (opt['badgeColor'] as Color).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      opt['badge'] as String,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: opt['badgeColor'] as Color,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                opt['subtitle'] as String,
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
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
