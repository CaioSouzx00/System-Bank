import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/haptic_feedback_utils.dart';
import '../../../../core/widgets/bank_button.dart';
import '../../../../core/widgets/bank_card.dart';
import '../../../../core/widgets/bank_shimmer.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../data/models/pix_key.dart';
import '../providers/pix_provider.dart';

class PixQrView extends ConsumerStatefulWidget {
  const PixQrView({super.key});

  @override
  ConsumerState<PixQrView> createState() => _PixQrViewState();
}

class _PixQrViewState extends ConsumerState<PixQrView> {
  String? _selectedKey;
  String _qrPayload = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialKey();
  }

  Future<void> _loadInitialKey() async {
    final keys = ref.read(pixKeysNotifierProvider).value ?? [];
    if (keys.isNotEmpty) {
      _selectedKey = keys.first.keyValue;
    } else {
      _selectedKey = 'contato@systembank.com.br';
    }
    await _generateQr(_selectedKey!);
  }

  Future<void> _generateQr(String key) async {
    setState(() => _isLoading = true);
    final repo = ref.read(pixRepositoryProvider);
    try {
      final payload = await repo.generateQrCode(key);
      if (mounted) {
        setState(() {
          _qrPayload = payload;
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
    final keys = ref.watch(pixKeysNotifierProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receber via Pix'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: ResponsiveMaxContentWidth(
        maxWidth: 500,
        child: SingleChildScrollView(
          padding: AppDimensions.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'QR Code Pix Instantâneo',
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Mostre este código para quem vai pagar ou compartilhe o código Copia e Cola.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                ),
              ),

              const SizedBox(height: 24),

              // QR Code Container
              BankCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (_isLoading)
                      const BankShimmerBox(width: 220, height: 220, borderRadius: AppDimensions.borderRadiusMd)
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppDimensions.borderRadiusMd,
                          border: Border.all(color: Colors.black12),
                        ),
                        child: QrImageView(
                          data: _qrPayload.isNotEmpty ? _qrPayload : 'System-Bank-Pix',
                          version: QrVersions.auto,
                          size: 200.0,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF1E1E2E),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF1E1E2E),
                          ),
                        ),
                      ),

                    const SizedBox(height: 18),

                    Text(
                      'Chave selecionada:',
                      style: AppTypography.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedKey ?? 'Nenhuma chave',
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons: Copiar e Compartilhar
              Row(
                children: [
                  Expanded(
                    child: BankButton(
                      label: 'Copiar Código',
                      icon: Icons.copy_rounded,
                      variant: BankButtonVariant.secondary,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _qrPayload));
                        HapticFeedbackUtils.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Código Pix Copia e Cola copiado!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BankButton(
                      label: 'Compartilhar',
                      icon: Icons.share_rounded,
                      onPressed: () {
                        HapticFeedbackUtils.selectionClick();
                        Share.share(
                          'Pague-me via Pix do System-Bank usando o código Copia e Cola:\n\n$_qrPayload',
                          subject: 'Cobrança Pix System-Bank',
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Key Selector (if multiple keys available)
              if (keys.isNotEmpty) ...[
                Text(
                  'Trocar Chave do QR Code',
                  style: AppTypography.titleSmall,
                ),
                const SizedBox(height: 10),
                ...keys.map((k) {
                  final isCurrent = _selectedKey == k.keyValue;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.vpn_key_rounded,
                      color: isCurrent ? bankTheme.primaryBrand : Colors.grey,
                    ),
                    title: Text(k.keyValue, style: AppTypography.bodyMedium),
                    subtitle: Text(k.keyType.label, style: AppTypography.labelSmall),
                    trailing: isCurrent
                        ? Icon(Icons.check_circle_rounded, color: bankTheme.primaryBrand)
                        : null,
                    onTap: () {
                      HapticFeedbackUtils.selectionClick();
                      setState(() => _selectedKey = k.keyValue);
                      _generateQr(k.keyValue);
                    },
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
