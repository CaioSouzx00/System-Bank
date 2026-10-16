import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/network/endpoints.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/haptic_feedback_utils.dart';
import '../../../../core/widgets/bank_button.dart';
import '../../../../core/widgets/bank_card.dart';
import '../../../../core/widgets/bank_text_field.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final _urlController = TextEditingController();
  bool _biometricsEnabled = true;
  bool _isCheckingHealth = false;

  @override
  void initState() {
    super.initState();
    final cache = ref.read(cacheStorageProvider);
    _urlController.text = cache.getCustomBaseUrl() ?? EnvConfig.defaultBaseUrl;
    _loadBiometrics();
  }

  Future<void> _loadBiometrics() async {
    final secure = ref.read(secureStorageProvider);
    final enabled = await secure.isBiometricsEnabled();
    if (mounted) setState(() => _biometricsEnabled = enabled);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testHealth() async {
    HapticFeedbackUtils.selectionClick();
    setState(() => _isCheckingHealth = true);

    final apiClient = ref.read(apiClientProvider);
    // Atualiza temporariamente ou salva a URL
    apiClient.updateBaseUrl(_urlController.text.trim());

    try {
      final response = await apiClient.get(Endpoints.health);
      setState(() => _isCheckingHealth = false);

      if (mounted) {
        HapticFeedbackUtils.successFeedback();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conexão OK! Resposta do System-Bank: ${response.statusCode}'),
            backgroundColor: AppColors.secondaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isCheckingHealth = false);
      if (mounted) {
        HapticFeedbackUtils.errorFeedback();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao conectar: $e'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankTheme = context.bankTheme;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
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
              // Theme Mode Selector
              Text('Aparência e Tema', style: AppTypography.titleSmall),
              const SizedBox(height: 10),
              BankCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.system,
                      groupValue: themeMode,
                      title: const Text('Padrão do Sistema'),
                      activeColor: bankTheme.primaryBrand,
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(themeModeProvider.notifier).setThemeMode(val);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.light,
                      groupValue: themeMode,
                      title: const Text('Tema Claro'),
                      activeColor: bankTheme.primaryBrand,
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(themeModeProvider.notifier).setThemeMode(val);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.dark,
                      groupValue: themeMode,
                      title: const Text('Tema Escuro (Dark Mode)'),
                      activeColor: bankTheme.primaryBrand,
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(themeModeProvider.notifier).setThemeMode(val);
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Security & Biometrics
              Text('Segurança e Acesso', style: AppTypography.titleSmall),
              const SizedBox(height: 10),
              BankCard(
                padding: const EdgeInsets.all(16),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Biometria (Face ID / Touch ID)'),
                  subtitle: const Text('Exigir biometria ao abrir o app e confirmar transferências'),
                  value: _biometricsEnabled,
                  activeColor: bankTheme.primaryBrand,
                  onChanged: (val) async {
                    HapticFeedbackUtils.selectionClick();
                    setState(() => _biometricsEnabled = val);
                    await ref.read(secureStorageProvider).setBiometricsEnabled(val);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Backend API URL Configuration
              Text('Servidor do Backend (Rust Axum)', style: AppTypography.titleSmall),
              const SizedBox(height: 10),
              BankCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BankTextField(
                      controller: _urlController,
                      label: 'Base URL da API',
                      hint: 'http://localhost:8080',
                      prefixIcon: const Icon(Icons.dns_outlined, size: 20),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: BankButton(
                            label: 'Testar / Health',
                            icon: Icons.network_check_rounded,
                            variant: BankButtonVariant.secondary,
                            isLoading: _isCheckingHealth,
                            onPressed: _testHealth,
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.outlined(
                          icon: const Icon(Icons.restart_alt_rounded),
                          tooltip: 'Restaurar padrão',
                          onPressed: () {
                            _urlController.text = EnvConfig.defaultBaseUrl;
                            ref.read(apiClientProvider).updateBaseUrl(EnvConfig.defaultBaseUrl);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // About App info
              BankCard(
                padding: const EdgeInsets.all(18),
                type: BankCardType.outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('System-Bank Core Banking', style: AppTypography.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Versão 1.0.0 • Axum + GnuCOBOL 3.2 + RabbitMQ + PostgreSQL 16',
                      style: AppTypography.bodySmall.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Desenvolvido com Flutter 3.24+, Riverpod 2.x, GoRouter e Material 3 Design System.',
                      style: AppTypography.bodySmall.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
