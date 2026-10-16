import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/haptic_feedback_utils.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/utils/pix_validator.dart';
import '../../../../core/widgets/bank_bottom_sheet.dart';
import '../../../../core/widgets/bank_button.dart';
import '../../../../core/widgets/bank_card.dart';
import '../../../../core/widgets/bank_status_badge.dart';
import '../../../../core/widgets/bank_text_field.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../routes/app_routes.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../providers/pix_provider.dart';

class PixSendView extends ConsumerStatefulWidget {
  const PixSendView({super.key});

  @override
  ConsumerState<PixSendView> createState() => _PixSendViewState();
}

class _PixSendViewState extends ConsumerState<PixSendView> {
  final _formKey = GlobalKey<FormState>();
  final _keyController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _detectedType = '';
  bool _isSending = false;

  @override
  void dispose() {
    _keyController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onKeyChanged(String value) {
    setState(() {
      _detectedType = PixValidator.detectKeyType(value);
    });
  }

  void _showConfirmationSheet() {
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
      title: 'Confirmar Envio Pix',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              CurrencyFormatter.format(amount),
              style: AppTypography.monetaryValue(
                fontSize: 34,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Transferência instantânea Pix',
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _summaryRow('Chave Destino', _keyController.text),
          if (_detectedType != 'Unknown')
            _summaryRow('Tipo de Chave', _detectedType),
          if (_descController.text.isNotEmpty)
            _summaryRow('Descrição', _descController.text),
          _summaryRow('Conta de Origem', selectedAccount?.formattedAccount ?? 'Conta Principal'),
          _summaryRow('Tarifa de Envio', 'Grátis (R\$ 0,00)', isSuccess: true),
          _summaryRow('ID de Correlação', correlationId, isMono: true),
          const SizedBox(height: 28),

          BankButton(
            label: 'Confirmar e Transferir',
            icon: Icons.check_rounded,
            isLoading: _isSending,
            onPressed: () async {
              Navigator.of(context).pop();
              await _executePayment(amount, correlationId);
            },
          ),
          const SizedBox(height: 12),
          BankButton(
            label: 'Cancelar',
            variant: BankButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _executePayment(double amount, String correlationId) async {
    setState(() => _isSending = true);

    final repo = ref.read(pixRepositoryProvider);

    try {
      final tx = await repo.initiatePayment(
        key: _keyController.text.trim(),
        amount: amount,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        correlationId: correlationId,
      );

      setState(() => _isSending = false);

      if (mounted) {
        HapticFeedbackUtils.successFeedback();
        _showSuccessDialog(tx);
      }
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        HapticFeedbackUtils.errorFeedback();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao processar Pix: $e'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(TransactionModel tx) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusLg),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.secondaryGreen, size: 28),
            const SizedBox(width: 10),
            const Text('Pix Enviado!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sua transferência de ${CurrencyFormatter.format(tx.amount)} foi aceita e está sendo liquidada.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),
            const BankStatusBadge(status: 'PROCESSED'),
            const SizedBox(height: 12),
            Text(
              'Correlation ID: ${tx.correlationId}',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.grey,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ],
        ),
        actions: [
          BankButton(
            label: 'Concluir',
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(AppRoutes.dashboard);
            },
          ),
        ],
      ),
    );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enviar Pix'),
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
                // Origin account card
                BankCard(
                  padding: const EdgeInsets.all(14),
                  type: BankCardType.outlined,
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 20, color: bankTheme.primaryBrand),
                      const SizedBox(width: 10),
                      Text(
                        selectedAccount != null
                            ? 'Débito em: ${selectedAccount.formattedAccount}'
                            : 'Conta Corrente Padrão',
                        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Key input
                BankTextField(
                  controller: _keyController,
                  label: 'Chave Pix de destino',
                  hint: 'CPF, e-mail, celular ou chave aleatória',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  onChanged: _onKeyChanged,
                  helperText: _detectedType.isNotEmpty && _detectedType != 'Unknown'
                      ? 'Tipo detectado: $_detectedType'
                      : null,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Informe a chave Pix';
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // Amount input
                BankTextField(
                  controller: _amountController,
                  label: 'Valor a transferir',
                  hint: 'R\$ 0,00',
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

                const SizedBox(height: 18),

                // Description input
                BankTextField(
                  controller: _descController,
                  label: 'Descrição ou mensagem (opcional)',
                  hint: 'Ex: Aluguel, almoço, serviços',
                  prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                  maxLines: 2,
                ),

                const SizedBox(height: 32),

                // Submit Action Button
                BankButton(
                  label: 'Avançar para Confirmação',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: _isSending,
                  onPressed: _showConfirmationSheet,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
