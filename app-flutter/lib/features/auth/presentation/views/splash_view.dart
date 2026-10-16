import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../routes/app_routes.dart';
import '../providers/auth_provider.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> {
  @override
  void initState() {
    super.initState();
    _checkNavigation();
  }

  Future<void> _checkNavigation() async {
    // Aguarda animação e checagem de sessão
    await Future.delayed(const Duration(milliseconds: 1600));

    if (!mounted) return;
    final authState = ref.read(authNotifierProvider);

    if (authState.isAuthenticated) {
      context.go(AppRoutes.dashboard);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Glowing Bank Icon
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primaryPurple, Color(0xFF5A0099)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.5),
                    blurRadius: 36,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                size: 48,
                color: Colors.white,
              ),
            )
                .animate()
                .scale(duration: 700.ms, curve: Curves.easeOutBack)
                .shimmer(delay: 500.ms, duration: 900.ms),

            const SizedBox(height: 28),

            Text(
              'System-Bank',
              style: AppTypography.displayMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 600.ms)
                .moveY(begin: 12, end: 0, duration: 600.ms),

            const SizedBox(height: 8),

            Text(
              'Next-Gen Core Banking Platform',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.7),
                letterSpacing: 0.5,
              ),
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}
