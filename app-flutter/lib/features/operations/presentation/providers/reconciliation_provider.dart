import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/models/reconciliation_models.dart';
import '../data/reconciliation_repository.dart';

final reconciliationRepositoryProvider = Provider<ReconciliationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReconciliationRepository(apiClient: apiClient);
});

class ReconciliationNotifier extends StateNotifier<AsyncValue<OperationalDashboardData>> {
  final ReconciliationRepository _repository;

  ReconciliationNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchMetrics();
  }

  Future<void> fetchMetrics() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repository.getMetrics();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> triggerJob() async {
    try {
      await _repository.triggerBatchReconciliation();
      await fetchMetrics();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final reconciliationNotifierProvider =
    StateNotifierProvider<ReconciliationNotifier, AsyncValue<OperationalDashboardData>>((ref) {
  final repo = ref.watch(reconciliationRepositoryProvider);
  return ReconciliationNotifier(repo);
});
