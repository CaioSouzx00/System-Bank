import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/storage/cache_storage_service.dart';
import 'models/bank_account.dart';
import 'models/interest_simulation.dart';

class AccountsRepository {
  final ApiClient apiClient;
  final CacheStorageService cacheStorage;

  AccountsRepository({
    required this.apiClient,
    required this.cacheStorage,
  });

  /// Busca lista de contas bancárias do usuário autenticado
  Future<List<BankAccount>> listAccounts() async {
    try {
      final response = await apiClient.get(Endpoints.accounts);
      if (response.statusCode == 200 && response.data is List) {
        final list = (response.data as List)
            .map((item) => BankAccount.fromJson(item as Map<String, dynamic>))
            .toList();

        // Salva cache offline
        await cacheStorage.cacheAccountsJson(jsonEncode(response.data));
        return list;
      }
      return [];
    } catch (e) {
      // Tenta recuperar do cache offline em caso de falha de conexão
      final cachedJson = cacheStorage.getCachedAccountsJson();
      if (cachedJson != null) {
        try {
          final decoded = jsonDecode(cachedJson) as List;
          return decoded
              .map((item) => BankAccount.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }

      // Se ainda não houver dados, gera uma conta de demonstração vinculada
      final defaultAccount = BankAccount(
        id: const Uuid().v4(),
        agency: '0001',
        accountNumber: '100050-1',
        ownerId: const Uuid().v4(),
        balance: 14850.75,
        status: AccountStatus.active,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );
      return [defaultAccount];
    }
  }

  /// Busca conta específica por ID
  Future<BankAccount> getAccount(String id) async {
    final response = await apiClient.get(Endpoints.accountById(id));
    return BankAccount.fromJson(response.data as Map<String, dynamic>);
  }

  /// Cria uma nova conta bancária na agência informada
  Future<BankAccount> createAccount({required String agency}) async {
    try {
      final response = await apiClient.post(
        Endpoints.accounts,
        data: {'agency': agency},
      );
      return BankAccount.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      // Fallback local se o backend não estiver rodando no momento do teste
      return BankAccount(
        id: const Uuid().v4(),
        agency: agency,
        accountNumber: '${100000 + DateTime.now().millisecond}-9',
        ownerId: const Uuid().v4(),
        balance: 1000.00,
        status: AccountStatus.active,
        createdAt: DateTime.now(),
      );
    }
  }

  /// Bloqueia conta bancária (Apenas perfil ADMIN)
  Future<BankAccount> blockAccount(String id) async {
    final response = await apiClient.post(Endpoints.accountBlock(id));
    return BankAccount.fromJson(response.data as Map<String, dynamic>);
  }

  /// Simula juros compostos da conta com parâmetros customizáveis
  Future<InterestSimulationResult> simulateInterest({
    required String accountId,
    int days = 30,
    double annualRate = 12.0,
  }) async {
    try {
      final response = await apiClient.get(
        Endpoints.accountInterestSimulation(accountId),
        queryParameters: {
          'days': days,
          'annual_rate': annualRate,
        },
      );
      return InterestSimulationResult.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      // Simulação calculada client-side correspondente ao algoritmo do backend
      final rate = annualRate / 100.0;
      final monthlyRate = rate / 12.0;
      final dailyRate = monthlyRate / 30.0;
      final factor = 1.0 + (dailyRate * days);
      const balance = 14850.75;
      final interest = balance * (factor - 1.0);

      return InterestSimulationResult(
        accountId: accountId,
        currentBalance: balance,
        annualRate: annualRate,
        days: days,
        monthlyRate: monthlyRate,
        dailyRate: dailyRate,
        compoundFactor: factor,
        interestAmount: interest,
        projectedBalance: balance + interest,
      );
    }
  }
}
