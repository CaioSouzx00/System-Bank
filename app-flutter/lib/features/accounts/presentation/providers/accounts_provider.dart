import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/accounts_repository.dart';
import '../data/models/bank_account.dart';

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final cacheStorage = ref.watch(cacheStorageProvider);

  return AccountsRepository(
    apiClient: apiClient,
    cacheStorage: cacheStorage,
  );
});

class AccountsNotifier extends StateNotifier<AsyncValue<List<BankAccount>>> {
  final AccountsRepository _repository;

  AccountsNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchAccounts();
  }

  Future<void> fetchAccounts() async {
    state = const AsyncValue.loading();
    try {
      final accounts = await _repository.listAccounts();
      state = AsyncValue.data(accounts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<BankAccount?> createAccount(String agency) async {
    try {
      final newAccount = await _repository.createAccount(agency: agency);
      final currentList = state.value ?? [];
      state = AsyncValue.data([newAccount, ...currentList]);
      return newAccount;
    } catch (e) {
      return null;
    }
  }

  Future<bool> blockAccount(String id) async {
    try {
      final updated = await _repository.blockAccount(id);
      final currentList = state.value ?? [];
      state = AsyncValue.data(
        currentList.map((a) => a.id == id ? updated : a).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

final accountsListNotifierProvider =
    StateNotifierProvider<AccountsNotifier, AsyncValue<List<BankAccount>>>((ref) {
  final repo = ref.watch(accountsRepositoryProvider);
  return AccountsNotifier(repo);
});

/// Conta atualmente selecionada para operações no app
final selectedAccountProvider = StateProvider<BankAccount?>((ref) {
  final accountsAsync = ref.watch(accountsListNotifierProvider);
  return accountsAsync.maybeWhen(
    data: (accounts) => accounts.isNotEmpty ? accounts.first : null,
    orElse: () => null,
  );
});

/// Estado de ocultar/mostrar saldo na Home (com persistência)
class HideBalanceNotifier extends StateNotifier<bool> {
  final Ref _ref;

  HideBalanceNotifier(this._ref) : super(false) {
    _loadPreference();
  }

  void _loadPreference() {
    final cache = _ref.read(cacheStorageProvider);
    state = cache.isBalanceHidden();
  }

  void toggle() {
    state = !state;
    _ref.read(cacheStorageProvider).setHideBalance(state);
  }
}

final hideBalanceProvider = StateNotifierProvider<HideBalanceNotifier, bool>((ref) {
  return HideBalanceNotifier(ref);
});
