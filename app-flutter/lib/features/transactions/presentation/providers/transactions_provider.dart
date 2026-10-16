import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../accounts/presentation/providers/accounts_provider.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/models/statement_query.dart';
import '../data/models/transaction_model.dart';
import '../data/transactions_repository.dart';

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final cacheStorage = ref.watch(cacheStorageProvider);

  return TransactionsRepository(
    apiClient: apiClient,
    cacheStorage: cacheStorage,
  );
});

final statementFilterProvider = StateProvider<StatementFilter>((ref) {
  return StatementFilter();
});

class StatementNotifier extends StateNotifier<AsyncValue<List<TransactionModel>>> {
  final TransactionsRepository _repository;
  final Ref _ref;

  StatementNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    fetchStatement();
  }

  Future<void> fetchStatement() async {
    final account = _ref.read(selectedAccountProvider);
    if (account == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    final filter = _ref.read(statementFilterProvider);

    try {
      final list = await _repository.getStatement(account.id, filter);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String> exportOfx() async {
    final account = _ref.read(selectedAccountProvider);
    if (account == null) return '';
    final filter = _ref.read(statementFilterProvider);
    return await _repository.exportOfxStatement(account.id, filter);
  }
}

final statementNotifierProvider =
    StateNotifierProvider<StatementNotifier, AsyncValue<List<TransactionModel>>>((ref) {
  final repo = ref.watch(transactionsRepositoryProvider);
  return StatementNotifier(repo, ref);
});

/// Últimas transações para o Dashboard
final recentTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final statementAsync = ref.watch(statementNotifierProvider);
  return statementAsync.maybeWhen(
    data: (list) => list.take(6).toList(),
    orElse: () => [],
  );
});
