enum PixKeyType {
  cpf('Cpf', 'CPF'),
  email('Email', 'E-mail'),
  phone('Phone', 'Telefone Celular'),
  random('Random', 'Chave Aleatória (EVP)');

  final String value;
  final String label;

  const PixKeyType(this.value, this.label);

  static PixKeyType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'email':
        return PixKeyType.email;
      case 'phone':
        return PixKeyType.phone;
      case 'random':
        return PixKeyType.random;
      case 'cpf':
      default:
        return PixKeyType.cpf;
    }
  }
}

class PixKey {
  final String id;
  final String accountId;
  final PixKeyType keyType;
  final String keyValue;
  final DateTime createdAt;

  const PixKey({
    required this.id,
    required this.accountId,
    required this.keyType,
    required this.keyValue,
    required this.createdAt,
  });

  factory PixKey.fromJson(Map<String, dynamic> json) {
    return PixKey(
      id: json['id'] as String? ?? '',
      accountId: json['account_id'] as String? ?? '',
      keyType: PixKeyType.fromString(json['key_type'] as String?),
      keyValue: json['key_value'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'account_id': accountId,
        'key_type': keyType.value,
        'key_value': keyValue,
        'created_at': createdAt.toIso8601String(),
      };
}

class PixPaymentRequest {
  final String key;
  final double amount;
  final String? description;
  final String correlationId;

  const PixPaymentRequest({
    required this.key,
    required this.amount,
    this.description,
    required this.correlationId,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'amount': amount.toStringAsFixed(2),
        if (description != null && description!.isNotEmpty) 'description': description,
        'correlation_id': correlationId,
      };
}

class PixQrResponse {
  final String payload;

  const PixQrResponse({required this.payload});

  factory PixQrResponse.fromJson(Map<String, dynamic> json) {
    return PixQrResponse(payload: json['payload'] as String? ?? '');
  }
}
