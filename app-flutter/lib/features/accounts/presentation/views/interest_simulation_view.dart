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
import '../../../../core/widgets/responsive_layout.dart';
import '../data/models/interest_simulation.dart';
import '../providers/accounts_provider.dart';

class InterestSimulationView extends ConsumerStatefulWidget {
  final String? accountId;

  const InterestSimulationView({super.key, this.accountId});

  @override
  ConsumerState<InterestSimulationView> createState() => _InterestSimulationViewState();
}

class _InterestSimulationViewState extends ConsumerState<InterestSimulationView> {
  int _selectedDays = 30;
  double _annualRate = 12.0;
  InterestSimulationResult? _result;
  bool _isLoading = true;

  final List<int> _daysPresets = [15, 30, 60, 90, 180, 365];

  @override
  void initState() {
    super.initState();
    _fetchSimulation();
  }

  Future<void> _fetchSimulation() async {
    setState(() => _isLoading = true);
    final targetAccountId = widget.accountId ??
        ref.read(selectedAccountProvider)?.id ??
        'default';

    final repo = ref.read(accountsRepositoryProvider);
    try {
      final res = await repo.simulateInterest(
        accountId: targetAccountId,
        days: _selectedDays,
        annualRate: _annualRate,
      );
      if (mounted) {
        setState(() {
          _result = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankTheme = context.bankTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulador de Rendimento'),
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
              Text(
                'Simulação de Juros Compostos',
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Cálculo diário de rentabilidade do backend COBOL integrado ao System-Bank.',
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                ),
              ),
              const SizedBox(height: 24),

              // Hero Result Card
              if (_isLoading)
                const BankShimmerCard(height: 200)
              else if (_result != null)
                BankCard(
                  type: BankCardType.gradient,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Saldo Projetado',
                            style: AppTypography.titleSmall.copyWith(
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: AppDimensions.borderRadiusPill,
                            ),
                            child: Text(
                              '+${CurrencyFormatter.format(_result!.interestAmount)}',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        CurrencyFormatter.format(_result!.projectedBalance),
                        style: AppTypography.monetaryValue(
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Saldo Atual',
                                style: AppTypography.labelSmall.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                CurrencyFormatter.format(_result!.currentBalance),
                                style: AppTypography.titleSmall.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Período',
                                style: AppTypography.labelSmall.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_result!.days} dias (${_annualRate.toStringAsFixed(1)}% a.a.)',
                                style: AppTypography.titleSmall.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 28),

              // Period Preset Chips
              Text(
                'Prazo da Aplicação (Dias)',
                style: AppTypography.titleSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _daysPresets.map((days) {
                  final isSelected = _selectedDays == days;
                  return ChoiceChip(
                    label: Text('$days dias'),
                    selected: isSelected,
                    selectedColor: bankTheme.primaryBrand,
                    labelStyle: AppTypography.labelSmall.copyWith(
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    onSelected: (val) {
                      if (val) {
                        HapticFeedbackUtils.selectionClick();
                        setState(() => _selectedDays = days);
                        _fetchSimulation();
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),

              // Annual Rate Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Taxa Anual de Rendimento',
                    style: AppTypography.titleSmall,
                  ),
                  Text(
                    '${_annualRate.toStringAsFixed(1)}% a.a.',
                    style: AppTypography.titleMedium.copyWith(
                      color: bankTheme.primaryBrand,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _annualRate,
                min: 8.0,
                max: 20.0,
                divisions: 24,
                activeColor: bankTheme.primaryBrand,
                label: '${_annualRate.toStringAsFixed(1)}%',
                onChanged: (val) {
                  setState(() => _annualRate = val);
                },
                onChangeEnd: (_) {
                  _fetchSimulation();
                },
              ),

              const SizedBox(height: 24),

              // Technical Metrics Breakdown
              if (_result != null) ...[
                Text(
                  'Detalhamento Financeiro (COBOL Engine)',
                  style: AppTypography.titleSmall,
                ),
                const SizedBox(height: 12),
                BankCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildMetricRow('Taxa Mensal Efetiva', '${(_result!.monthlyRate * 100).toStringAsFixed(4)}%'),
                      const Divider(height: 20),
                      _buildMetricRow('Taxa Diária Composta', '${(_result!.dailyRate * 100).toStringAsFixed(6)}%'),
                      const Divider(height: 20),
                      _buildMetricRow('Fator de Capitalização', _result!.compoundFactor.toStringAsFixed(6)),
                      const Divider(height: 20),
                      _buildMetricRow('Rendimento Líquido Estimado', CurrencyFormatter.format(_result!.interestAmount), isHighlight: true),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: isHighlight
              ? AppTypography.titleSmall.copyWith(
                  color: AppColors.secondaryGreen,
                  fontWeight: FontWeight.w700,
                )
              : AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
