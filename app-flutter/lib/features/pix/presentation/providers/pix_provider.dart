import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/models/pix_key.dart';
import '../data/pix_repository.dart';

final pixRepositoryProvider = Provider<PixRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PixRepository(apiClient: apiClient);
});

class PixKeysNotifier extends StateNotifier<AsyncValue<List<PixKey>>> {
  final PixRepository _repository;

  PixKeysNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchKeys();
  }

  Future<void> fetchKeys() async {
    state = const AsyncValue.loading();
    try {
      final keys = await _repository.listKeys();
      state = AsyncValue.data(keys);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> registerKey({
    required PixKeyType keyType,
    required String keyValue,
  }) async {
    try {
      final newKey = await _repository.registerKey(
        keyType: keyType,
        keyValue: keyValue,
      );
      final current = state.value ?? [];
      state = AsyncValue.data([newKey, ...current]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeKey(String id) async {
    try {
      await _repository.removeKey(id);
      final current = state.value ?? [];
      state = AsyncValue.data(current.where((k) => k.id != id).toList());
      return true;
    } catch (e) {
      return false;
    }
  }
}

final pixKeysNotifierProvider =
    StateNotifierProvider<PixKeysNotifier, AsyncValue<List<PixKey>>>((ref) {
  final repo = ref.watch(pixRepositoryProvider);
  return PixKeysNotifier(repo);
});
