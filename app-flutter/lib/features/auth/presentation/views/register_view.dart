import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/haptic_feedback_utils.dart';
import '../../../../core/utils/pix_validator.dart';
import '../../../../core/widgets/bank_button.dart';
import '../../../../core/widgets/bank_text_field.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../routes/app_routes.dart';
import '../providers/auth_provider.dart';

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedbackUtils.errorFeedback();
      return;
    }

    setState(() => _isLoading = true);

    // Registra sessão simulada
    await Future.delayed(const Duration(milliseconds: 700));

    final success = await ref.read(authNotifierProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    setState(() => _isLoading = false);

    if (success && mounted) {
      HapticFeedbackUtils.successFeedback();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta criada com sucesso! Seja bem-vindo ao System-Bank.'),
          backgroundColor: AppColors.secondaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankTheme = context.bankTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Abrir Conta'),
      ),
      body: SafeArea(
        child: ResponsiveMaxContentWidth(
          maxWidth: 480,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Comece a usar o System-Bank hoje',
                    style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Preencha seus dados para abrir sua conta digital com agência e Pix instantâneo.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                    ),
                  ),

                  const SizedBox(height: 28),

                  BankTextField(
                    controller: _nameController,
                    label: 'Nome completo',
                    hint: 'Ex: Caio Souza',
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Informe seu nome';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  BankTextField(
                    controller: _cpfController,
                    label: 'CPF',
                    hint: '000.000.000-00',
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                    validator: (val) {
                      if (val == null || !PixValidator.isValidCpf(val)) {
                        return 'Informe um CPF válido com 11 dígitos';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  BankTextField(
                    controller: _emailController,
                    label: 'E-mail',
                    hint: 'seu.email@exemplo.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                    validator: (val) {
                      if (val == null || !PixValidator.isValidEmail(val)) {
                        return 'Informe um e-mail válido';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  BankTextField(
                    controller: _passwordController,
                    label: 'Crie uma senha de acesso',
                    hint: 'Mínimo de 6 caracteres',
                    isPassword: true,
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    validator: (val) {
                      if (val == null || val.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  BankButton(
                    label: 'Finalizar Abertura de Conta',
                    icon: Icons.check_circle_outline_rounded,
                    isLoading: _isLoading,
                    onPressed: _submitRegister,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
