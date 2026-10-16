import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/haptic_feedback_utils.dart';
import '../../../../core/widgets/bank_button.dart';
import '../../../../core/widgets/bank_card.dart';
import '../../../../core/widgets/bank_text_field.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/user_role.dart';
import '../providers/auth_provider.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'cliente@systembank.com.br');
  final _passwordController = TextEditingController(text: '123456');
  UserRole _selectedRole = UserRole.client;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRoleChanged(UserRole role) {
    HapticFeedbackUtils.selectionClick();
    setState(() {
      _selectedRole = role;
      switch (role) {
        case UserRole.client:
          _emailController.text = 'cliente@systembank.com.br';
          break;
        case UserRole.operator:
          _emailController.text = 'operador@systembank.com.br';
          break;
        case UserRole.admin:
          _emailController.text = 'admin@systembank.com.br';
          break;
      }
    });
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedbackUtils.errorFeedback();
      return;
    }

    final success = await ref.read(authNotifierProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole,
        );

    if (success && mounted) {
      HapticFeedbackUtils.successFeedback();
      context.go(AppRoutes.dashboard);
    } else if (mounted) {
      final error = ref.read(authNotifierProvider).errorMessage ?? 'Falha na autenticação';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankTheme = context.bankTheme;
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: ResponsiveMaxContentWidth(
          maxWidth: 480,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // Brand Icon & Welcome
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: bankTheme.primaryBrand,
                        borderRadius: AppDimensions.borderRadiusLg,
                        boxShadow: [
                          BoxShadow(
                            color: bankTheme.primaryBrand.withOpacity(0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 24),

                  Text(
                    'Bem-vindo ao\nSystem-Bank',
                    textAlign: TextAlign.center,
                    style: AppTypography.displayMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 8),

                  Text(
                    'Core banking moderno com segurança de nível institucional',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 28),

                  // Role Selector Tabs (CLIENT, OPERATOR, ADMIN)
                  Text(
                    'Selecione o perfil de acesso:',
                    style: AppTypography.labelSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: bankTheme.badgeBackground,
                      borderRadius: AppDimensions.borderRadiusMd,
                    ),
                    child: Row(
                      children: UserRole.values.map((role) {
                        final isSelected = _selectedRole == role;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => _onRoleChanged(role),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? bankTheme.primaryBrand : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: bankTheme.primaryBrand.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                role.label,
                                textAlign: TextAlign.center,
                                style: AppTypography.labelSmall.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Fields
                  BankTextField(
                    controller: _emailController,
                    label: 'E-mail corporativo / pessoal',
                    hint: 'seu.email@exemplo.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe seu e-mail';
                      }
                      if (!value.contains('@')) {
                        return 'E-mail inválido';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  BankTextField(
                    controller: _passwordController,
                    label: 'Senha de acesso',
                    hint: '••••••••',
                    isPassword: true,
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    validator: (value) {
                      if (value == null || value.length < 4) {
                        return 'Senha mínima de 4 dígitos';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        HapticFeedbackUtils.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Instruções de recuperação enviadas para o e-mail cadastrado.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Text(
                        'Esqueci minha senha',
                        style: AppTypography.labelSmall.copyWith(
                          color: bankTheme.primaryBrand,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Login Button
                  BankButton(
                    label: 'Acessar Conta',
                    icon: Icons.login_rounded,
                    isLoading: authState.isLoading,
                    onPressed: _submitLogin,
                  ),

                  const SizedBox(height: 16),

                  // Biometrics Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        onPressed: () async {
                          HapticFeedbackUtils.mediumImpact();
                          await _submitLogin();
                        },
                        icon: const Icon(Icons.fingerprint_rounded, size: 28),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(14),
                          backgroundColor: bankTheme.badgeBackground,
                          foregroundColor: bankTheme.primaryBrand,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Create Account Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Não tem uma conta bancária?',
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedbackUtils.lightImpact();
                          context.push(AppRoutes.register);
                        },
                        child: Text(
                          'Abra sua conta',
                          style: AppTypography.titleSmall.copyWith(
                            color: bankTheme.primaryBrand,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
