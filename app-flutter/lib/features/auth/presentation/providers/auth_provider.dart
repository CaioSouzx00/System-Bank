import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/cache_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/auth_repository.dart';
import '../../data/models/user_profile.dart';
import '../../domain/user_role.dart';

// Storage Providers
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final cacheStorageProvider = Provider<CacheStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CacheStorageService(prefs);
});

// Network Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final cacheStorage = ref.watch(cacheStorageProvider);

  return ApiClient(
    secureStorage: secureStorage,
    cacheStorage: cacheStorage,
    onUnauthorized: () {
      ref.read(authNotifierProvider.notifier).logout();
    },
  );
});

// Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);

  return AuthRepository(
    apiClient: apiClient,
    secureStorage: secureStorage,
  );
});

// Auth State
class AuthState {
  final bool isLoading;
  final AuthSession? session;
  final String? errorMessage;
  final bool isInitialized;

  const AuthState({
    this.isLoading = false,
    this.session,
    this.errorMessage,
    this.isInitialized = false,
  });

  bool get isAuthenticated => session != null && !session!.isExpired;
  UserProfile? get currentUser => session?.user;
  UserRole get currentRole => currentUser?.role ?? UserRole.client;

  AuthState copyWith({
    bool? isLoading,
    AuthSession? session,
    String? errorMessage,
    bool? isInitialized,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      session: session ?? this.session,
      errorMessage: errorMessage,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    checkCurrentSession();
  }

  Future<void> checkCurrentSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final session = await _repository.getCurrentSession();
      state = state.copyWith(
        isLoading: false,
        session: session,
        isInitialized: true,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, isInitialized: true);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
    UserRole role = UserRole.client,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final session = await _repository.login(
        email: email,
        password: password,
        role: role,
      );
      state = state.copyWith(isLoading: false, session: session);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> switchRole(UserRole newRole) async {
    if (state.currentUser == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final updatedUser = state.currentUser!.copyWith(role: newRole);
      final updatedSession = AuthSession(
        token: state.session!.token,
        user: updatedUser,
        expiresAt: state.session!.expiresAt,
      );
      state = state.copyWith(isLoading: false, session: updatedSession);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _repository.logout();
    state = state.copyWith(isLoading: false, session: null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
