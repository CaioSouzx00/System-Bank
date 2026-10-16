import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/haptic_feedback_utils.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/widgets/bank_bottom_sheet.dart';
import '../../../../core/widgets/bank_button.dart';
import '../../../../core/widgets/bank_card.dart';
import '../../../../core/widgets/bank_text_field.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../routes/app_routes.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../data/models/transaction_model.dart';
import '../providers/transactions_provider.dart';
import 'transaction_status_tracking_view.dart';

class NewTransactionView extends ConsumerStatefulWidget {
  final String? initialType;

  const NewTransactionView({super.key, this.initialType});

  @override
  ConsumerState<NewTransactionView> createState() => _NewTransactionViewState();
}

class _NewTransactionViewState extends ConsumerState<NewTransactionView> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _destinationController = TextEditingController();
  late TransactionType _selectedType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedType = TransactionType.fromString(widget.initialType ?? 'TRANSFER');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType type) {
    HapticFeedbackUtils.selectionClick();
    setState(() => _selectedType = type);
  }

  void _showConfirmation() {
    if (!_formKey.currentState!.validate()) {
      HapticFeedbackUtils.errorFeedback();
      return;
    }

    final amount = CurrencyFormatter.parse(_amountController.text);
    final selectedAccount = ref.read(selectedAccountProvider);
    final correlationId = IdGenerator.generateCorrelationId();

    HapticFeedbackUtils.mediumImpact();

    showBankBottomSheet(
      context: context,
      title: 'Confirmar Transação',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              CurrencyFormatter.format(amount),
              style: AppTypography.monetaryValue(
                fontSize: 32,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Operação: ${_selectedType.label}',
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 20),

          _summaryRow('Conta de Origem', selectedAccount?.formattedAccount ?? 'Conta Principal'),
          if (_selectedType == TransactionType.transfer)
            _summaryRow('Conta Destino (UUID)', _destinationController.text, isMono: true),
          _summaryRow('Idempotência', correlationId, isMono: true),
          _summaryRow('Tarifa', 'Isento (R\$ 0,00)', isSuccess: true),

          const SizedBox(height: 28),

          BankButton(
            label: 'Executar Transação',
            icon: Icons.check_circle_rounded,
            isLoading: _isLoading,
            onPressed: () async {
              Navigator.of(context).pop();
              await _executeTransaction(amount, correlationId);
            },
          ),
          const SizedBox(height: 10),
          BankButton(
            label: 'Voltar',
            variant: BankButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _executeTransaction(double amount, String correlationId) async {
    setState(() => _isLoading = true);

    final selectedAccount = ref.read(selectedAccountProvider);
    final repo = ref.read(transactionsRepositoryProvider);

    try {
      final tx = await repo.createTransaction(
        accountId: selectedAccount?.id ?? IdGenerator.generateUuid(),
        destinationAccountId: _selectedType == TransactionType.transfer
            ? _destinationController.text.trim()
            : null,
        type: _selectedType,
        amount: amount,
        correlationId: correlationId,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        // Redireciona para tela de acompanhamento assíncrono (polling PENDING -> PROCESSED)
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TransactionStatusTrackingView(initialTransaction: tx),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _summaryRow(String label, String value, {bool isMono = false, bool isSuccess = false}) {
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
                  : isSuccess
                      ? AppTypography.labelSmall.copyWith(color: AppColors.secondaryGreen, fontWeight: FontWeight.w700)
                      : AppTypography.titleSmall,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bankTheme = context.bankTheme;
    final selectedAccount = ref.watch(selectedAccountProvider);

    final allowedTypes = [
      TransactionType.transfer,
      TransactionType.debit,
      TransactionType.credit,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Movimentação'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: ResponsiveMaxContentWidth(
        maxWidth: 600,
        child: SingleChildScrollView(
          padding: AppDimensions.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Account origin
                BankCard(
                  padding: const EdgeInsets.all(14),
                  type: BankCardType.outlined,
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_rounded, size: 20, color: bankTheme.primaryBrand),
                      const SizedBox(width: 10),
                      Text(
                        selectedAccount != null
                            ? 'Conta Origem: ${selectedAccount.formattedAccount}'
                            : 'Conta Corrente Padrão',
                        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Type Chips
                Text('Tipo de Movimentação', style: AppTypography.titleSmall),
                const SizedBox(height: 10),
                Row(
                  children: allowedTypes.map((type) {
                    final isSelected = _selectedType == type;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Center(child: Text(type.label)),
                          selected: isSelected,
                          selectedColor: bankTheme.primaryBrand,
                          labelStyle: AppTypography.labelSmall.copyWith(
                            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          onSelected: (_) => _onTypeChanged(type),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 22),

                // Amount
                BankTextField(
                  controller: _amountController,
                  label: 'Valor da operação',
                  hint: '0,00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 6),
                    child: Text(
                      'R\$',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Informe o valor';
                    final parsed = CurrencyFormatter.parse(val);
                    if (parsed <= 0) return 'O valor deve ser maior que R\$ 0,00';
                    return null;
                  },
                ),

                // Destination account field (if transfer)
                if (_selectedType == TransactionType.transfer) ...[
                  const SizedBox(height: 18),
                  BankTextField(
                    controller: _destinationController,
                    label: 'Conta de destino (UUID)',
                    hint: 'Ex: 550e8400-e29b-41d4-a716-446655440000',
                    prefixIcon: const Icon(Icons.account_balance_outlined, size: 20),
                    validator: (val) {
                      if (_selectedType == TransactionType.transfer && (val == null || val.trim().isEmpty)) {
                        return 'Informe o UUID da conta destino';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 32),

                BankButton(
                  label: 'Avançar para Confirmação',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: _isLoading,
                  onPressed: _showConfirmation,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
