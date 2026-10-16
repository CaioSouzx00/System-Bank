import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_theme_extension.dart';
import '../core/utils/haptic_feedback_utils.dart';
import '../core/widgets/responsive_layout.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    HapticFeedbackUtils.selectionClick();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bankTheme = context.bankTheme;
    final isTabletOrWeb = !ResponsiveLayout.isMobile(context);

    if (isTabletOrWeb) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onTap,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bankTheme.primaryBrand,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: Text('Início'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: Text('Extrato'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.bolt_outlined),
                  selectedIcon: Icon(Icons.bolt_rounded),
                  label: Text('Pix'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                  label: Text('Contas'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: Text('Perfil'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    // Mobile: Bottom Navigation Bar
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        indicatorColor: bankTheme.primaryBrand.withOpacity(0.14),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: bankTheme.primaryBrand),
            label: 'Início',
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: bankTheme.primaryBrand),
            label: 'Extrato',
          ),
          NavigationDestination(
            icon: const Icon(Icons.bolt_outlined),
            selectedIcon: Icon(Icons.bolt_rounded, color: bankTheme.primaryBrand),
            label: 'Pix',
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: bankTheme.primaryBrand),
            label: 'Contas',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: bankTheme.primaryBrand),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
