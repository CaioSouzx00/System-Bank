import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/accounts/presentation/views/accounts_list_view.dart';
import '../features/accounts/presentation/views/create_account_view.dart';
import '../features/accounts/presentation/views/interest_simulation_view.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/views/login_view.dart';
import '../features/auth/presentation/views/register_view.dart';
import '../features/auth/presentation/views/splash_view.dart';
import '../features/dashboard/presentation/views/dashboard_view.dart';
import '../features/operations/presentation/views/reconciliation_dashboard_view.dart';
import '../features/pix/presentation/views/pix_hub_view.dart';
import '../features/pix/presentation/views/pix_keys_management_view.dart';
import '../features/pix/presentation/views/pix_qr_view.dart';
import '../features/pix/presentation/views/pix_register_key_view.dart';
import '../features/pix/presentation/views/pix_send_view.dart';
import '../features/profile/presentation/views/profile_view.dart';
import '../features/profile/presentation/views/settings_view.dart';
import '../features/transactions/presentation/views/new_transaction_view.dart';
import '../features/transactions/presentation/views/statement_view.dart';
import 'app_routes.dart';
import 'scaffold_with_nav_bar.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _sectionNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'section');

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      if (!authState.isInitialized) return null;

      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isLogin = state.matchedLocation == AppRoutes.login;
      final isRegister = state.matchedLocation == AppRoutes.register;

      if (!authState.isAuthenticated) {
        if (!isLogin && !isRegister && !isSplash) {
          return AppRoutes.login;
        }
        return null;
      }

      // If authenticated and tries to go to login or splash, send to dashboard
      if (isLogin || isSplash) {
        return AppRoutes.dashboard;
      }

      // Role guard for Operational area
      if (state.matchedLocation.startsWith('/operations')) {
        if (!authState.currentRole.isStaff) {
          return AppRoutes.dashboard;
        }
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashView(),
      ),

      // Auth
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterView(),
      ),

      // App Shell with BottomNavigationBar / NavigationRail
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard (Início)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardView(),
              ),
            ],
          ),

          // Branch 1: Extrato
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.statement,
                builder: (context, state) => const StatementView(),
              ),
            ],
          ),

          // Branch 2: Pix Hub
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.pix,
                builder: (context, state) => const PixHubView(),
              ),
            ],
          ),

          // Branch 3: Contas
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.accounts,
                builder: (context, state) => const AccountsListView(),
              ),
            ],
          ),

          // Branch 4: Perfil
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileView(),
              ),
            ],
          ),
        ],
      ),

      // Specific Nested Routes
      GoRoute(
        path: AppRoutes.createAccount,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateAccountView(),
      ),
      GoRoute(
        path: AppRoutes.interestSimulation,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final accountId = state.uri.queryParameters['accountId'];
          return InterestSimulationView(accountId: accountId);
        },
      ),

      // PIX Sub-routes
      GoRoute(
        path: AppRoutes.pixSend,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PixSendView(),
      ),
      GoRoute(
        path: AppRoutes.pixQr,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PixQrView(),
      ),
      GoRoute(
        path: AppRoutes.pixKeys,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PixKeysManagementView(),
      ),
      GoRoute(
        path: AppRoutes.pixRegisterKey,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PixRegisterKeyView(),
      ),

      // Transactions Sub-routes
      GoRoute(
        path: AppRoutes.newTransaction,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final type = state.uri.queryParameters['type'];
          return NewTransactionView(initialType: type);
        },
      ),

      // Operations & Reconciliation (OPERATOR & ADMIN only)
      GoRoute(
        path: AppRoutes.reconciliation,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReconciliationDashboardView(),
      ),

      // Settings
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsView(),
      ),
    ],
  );
});
