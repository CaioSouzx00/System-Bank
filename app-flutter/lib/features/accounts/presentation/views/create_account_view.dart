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
import '../providers/accounts_provider.dart';

class CreateAccountView extends ConsumerStatefulWidget {
  const CreateAccountView({super.key});

  @override
  ConsumerState<CreateAccountView> createState() => _CreateAccountViewState();
}

class _CreateAccountViewState extends ConsumerState<CreateAccountView> {
  String _selectedAgency = '0001';
  bool _isLoading = false;

  final List<Map<String, String>> _agencies = [
    {
      'code': '0001',
      'name': 'Agência Central (São Paulo)',
      'desc': 'Agência matriz com suporte operacional integral e Pix 24/7'
    },
    {
      'code': '0002',
      'name': 'Agência Faria Lima (Corporate)',
      'desc': 'Agência focada em contas corporativas e alto volume'
    },
    {
      'code': '0003',
      'name': 'Agência Rio de Janeiro',
      'desc': 'Agência regional centro'
    },
  ];

  Future<void> _handleCreate() async {
    setState(() => _isLoading = true);

    final newAccount = await ref
        .read(accountsListNotifierProvider.notifier)
        .createAccount(_selectedAgency);

    setState(() => _isLoading = false);

    if (newAccount != null && mounted) {
      HapticFeedbackUtils.successFeedback();
      ref.read(selectedAccountProvider.notifier).state = newAccount;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conta ${newAccount.accountNumber} criada com sucesso na agência $_selectedAgency!'),
          backgroundColor: AppColors.secondaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankTheme = context.bankTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Conta Bancária'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: ResponsiveMaxContentWidth(
        maxWidth: 600,
        child: SingleChildScrollView(
          padding: AppDimensions.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Escolha sua Agência',
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'A numeração e o dígito verificador da sua nova conta serão gerados automaticamente pelo core banking.',
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                ),
              ),
              const SizedBox(height: 24),

              ..._agencies.map((agency) {
                final isSelected = _selectedAgency == agency['code'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BankCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () {
                      HapticFeedbackUtils.selectionClick();
                      setState(() {
                        _selectedAgency = agency['code']!;
                      });
                    },
                    borderRadius: AppDimensions.borderRadiusMd,
                    type: isSelected ? BankCardType.surface : BankCardType.outlined,
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? bankTheme.primaryBrand.withOpacity(0.12)
                                : bankTheme.badgeBackground,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              agency['code']!,
                              style: AppTypography.titleSmall.copyWith(
                                color: isSelected ? bankTheme.primaryBrand : AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                agency['name']!,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                agency['desc']!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Radio<String>(
                          value: agency['code']!,
                          groupValue: _selectedAgency,
                          activeColor: bankTheme.primaryBrand,
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedAgency = val);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 32),

              BankButton(
                label: 'Confirmar Abertura de Conta',
                icon: Icons.check_circle_rounded,
                isLoading: _isLoading,
                onPressed: _handleCreate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
