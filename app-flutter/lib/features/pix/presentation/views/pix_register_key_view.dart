import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/haptic_feedback_utils.dart';
import '../../../../core/utils/pix_validator.dart';
import '../../../../core/widgets/bank_button.dart';
import '../../../../core/widgets/bank_text_field.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../data/models/pix_key.dart';
import '../providers/pix_provider.dart';

class PixRegisterKeyView extends ConsumerStatefulWidget {
  const PixRegisterKeyView({super.key});

  @override
  ConsumerState<PixRegisterKeyView> createState() => _PixRegisterKeyViewState();
}

class _PixRegisterKeyViewState extends ConsumerState<PixRegisterKeyView> {
  final _formKey = GlobalKey<FormState>();
  final _keyController = TextEditingController();
  PixKeyType _selectedType = PixKeyType.cpf;
  bool _isLoading = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  void _onTypeChanged(PixKeyType type) {
    HapticFeedbackUtils.selectionClick();
    setState(() {
      _selectedType = type;
      if (type == PixKeyType.random) {
        _keyController.text = const Uuid().v4();
      } else {
        _keyController.clear();
      }
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedbackUtils.errorFeedback();
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(pixKeysNotifierProvider.notifier).registerKey(
          keyType: _selectedType,
          keyValue: _keyController.text.trim(),
        );

    setState(() => _isLoading = false);

    if (success && mounted) {
      HapticFeedbackUtils.successFeedback();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chave Pix registrada com sucesso!'),
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
        title: const Text('Registrar Chave Pix'),
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
                Text(
                  'Tipo de Chave',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: PixKeyType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return ChoiceChip(
                      label: Text(type.label),
                      selected: isSelected,
                      selectedColor: bankTheme.primaryBrand,
                      labelStyle: AppTypography.labelSmall.copyWith(
                        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      onSelected: (selected) {
                        if (selected) _onTypeChanged(type);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                BankTextField(
                  controller: _keyController,
                  label: _getLabelForType(),
                  hint: _getHintForType(),
                  readOnly: _selectedType == PixKeyType.random,
                  keyboardType: _getKeyboardType(),
                  prefixIcon: Icon(_getIconForType(), size: 20),
                  suffixIcon: _selectedType == PixKeyType.random
                      ? IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'Gerar outro UUID',
                          onPressed: () {
                            HapticFeedbackUtils.selectionClick();
                            setState(() {
                              _keyController.text = const Uuid().v4();
                            });
                          },
                        )
                      : null,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Informe o valor da chave';
                    switch (_selectedType) {
                      case PixKeyType.cpf:
                        if (!PixValidator.isValidCpf(val)) return 'CPF inválido';
                        break;
                      case PixKeyType.email:
                        if (!PixValidator.isValidEmail(val)) return 'E-mail inválido';
                        break;
                      case PixKeyType.phone:
                        if (!PixValidator.isValidPhone(val)) return 'Telefone com DDD inválido';
                        break;
                      case PixKeyType.random:
                        if (!PixValidator.isValidRandomKey(val)) return 'Chave aleatória UUID inválida';
                        break;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                BankButton(
                  label: 'Cadastrar Chave',
                  icon: Icons.check_circle_rounded,
                  isLoading: _isLoading,
                  onPressed: _handleRegister,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getLabelForType() {
    switch (_selectedType) {
      case PixKeyType.cpf:
        return 'CPF do titular';
      case PixKeyType.email:
        return 'Endereço de e-mail';
      case PixKeyType.phone:
        return 'Celular com DDD';
      case PixKeyType.random:
        return 'Chave Aleatória (EVP gerada)';
    }
  }

  String _getHintForType() {
    switch (_selectedType) {
      case PixKeyType.cpf:
        return '000.000.000-00';
      case PixKeyType.email:
        return 'exemplo@systembank.com.br';
      case PixKeyType.phone:
        return '11999998888';
      case PixKeyType.random:
        return 'UUID gerado automaticamente';
    }
  }

  TextInputType _getKeyboardType() {
    switch (_selectedType) {
      case PixKeyType.cpf:
      case PixKeyType.phone:
        return TextInputType.number;
      case PixKeyType.email:
        return TextInputType.emailAddress;
      case PixKeyType.random:
        return TextInputType.text;
    }
  }

  IconData _getIconForType() {
    switch (_selectedType) {
      case PixKeyType.cpf:
        return Icons.badge_outlined;
      case PixKeyType.email:
        return Icons.mail_outline_rounded;
      case PixKeyType.phone:
        return Icons.phone_android_rounded;
      case PixKeyType.random:
        return Icons.vpn_key_rounded;
    }
  }
}
