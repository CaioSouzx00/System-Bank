import 'package:uuid/uuid.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/utils/id_generator.dart';
import '../../transactions/data/models/transaction_model.dart';
import 'models/pix_key.dart';

class PixRepository {
  final ApiClient apiClient;

  PixRepository({required this.apiClient});

  /// Lista todas as chaves Pix cadastradas na conta do usuário
  Future<List<PixKey>> listKeys() async {
    try {
      final response = await apiClient.get(Endpoints.pixKeys);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => PixKey.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      // Mock para preview local
      return [
        PixKey(
          id: const Uuid().v4(),
          accountId: const Uuid().v4(),
          keyType: PixKeyType.cpf,
          keyValue: '123.456.789-00',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        PixKey(
          id: const Uuid().v4(),
          accountId: const Uuid().v4(),
          keyType: PixKeyType.email,
          keyValue: 'contato@systembank.com.br',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];
    }
  }

  /// Cadastra uma nova chave Pix (CPF, Email, Phone, Random)
  Future<PixKey> registerKey({
    required PixKeyType keyType,
    required String keyValue,
  }) async {
    try {
      final response = await apiClient.post(
        Endpoints.pixKeys,
        data: {
          'key_type': keyType.value,
          'key_value': keyValue,
        },
      );
      return PixKey.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return PixKey(
        id: const Uuid().v4(),
        accountId: const Uuid().v4(),
        keyType: keyType,
        keyValue: keyValue,
        createdAt: DateTime.now(),
      );
    }
  }

  /// Exclui uma chave Pix pelo ID
  Future<void> removeKey(String id) async {
    await apiClient.delete(Endpoints.pixKeyById(id));
  }

  /// Inicia envio de Pix para uma chave de destino
  Future<TransactionModel> initiatePayment({
    required String key,
    required double amount,
    String? description,
    String? correlationId,
  }) async {
    final corrId = correlationId ?? IdGenerator.generateCorrelationId();

    final req = PixPaymentRequest(
      key: key,
      amount: amount,
      description: description,
      correlationId: corrId,
    );

    try {
      final response = await apiClient.post(
        Endpoints.pixPayment,
        data: req.toJson(),
      );
      return TransactionModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      // Fallback de demonstração
      return TransactionModel(
        id: const Uuid().v4(),
        accountId: const Uuid().v4(),
        type: TransactionType.debit,
        amount: amount,
        status: TransactionStatus.pending,
        correlationId: corrId,
        createdAt: DateTime.now(),
      );
    }
  }

  /// Gera a payload de QR Code Pix padrão BACEN (EMV BR Code)
  Future<String> generateQrCode(String key) async {
    try {
      final response = await apiClient.get(Endpoints.pixQrCode(key));
      final qrResponse = PixQrResponse.fromJson(response.data as Map<String, dynamic>);
      return qrResponse.payload;
    } catch (_) {
      // Retorna payload padrão simulada BR Code
      return '00020126580014br.gov.bcb.pix0136${key}5204000053039865802BR5911System-Bank6009Sao Paulo62070503***6304';
    }
  }
}
