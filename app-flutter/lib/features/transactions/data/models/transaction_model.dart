enum TransactionType {
  debit('DEBIT', 'Débito', 'Saída de recursos da conta'),
  credit('CREDIT', 'Crédito', 'Entrada de recursos na conta'),
  transfer('TRANSFER', 'Transferência', 'Transferência entre contas'),
  fee('FEE', 'Tarifa', 'Tarifa operacional de serviço');

  final String value;
  final String label;
  final String description;

  const TransactionType(this.value, this.label, this.description);

  static TransactionType fromString(String? type) {
    switch (type?.toUpperCase()) {
      case 'CREDIT':
        return TransactionType.credit;
      case 'TRANSFER':
        return TransactionType.transfer;
      case 'FEE':
        return TransactionType.fee;
      case 'DEBIT':
      default:
        return TransactionType.debit;
    }
  }

  bool get isIncome => this == TransactionType.credit;
}

enum TransactionStatus {
  pending('PENDING', 'Pendente'),
  processed('PROCESSED', 'Processada'),
  failed('FAILED', 'Falhou'),
  reversed('REVERSED', 'Estornada');

  final String value;
  final String label;

  const TransactionStatus(this.value, this.label);

  static TransactionStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'PROCESSED':
        return TransactionStatus.processed;
      case 'FAILED':
        return TransactionStatus.failed;
      case 'REVERSED':
        return TransactionStatus.reversed;
      case 'PENDING':
      default:
        return TransactionStatus.pending;
    }
  }

  bool get isPending => this == TransactionStatus.pending;
  bool get isProcessed => this == TransactionStatus.processed;
  bool get isFailed => this == TransactionStatus.failed;
}

class TransactionModel {
  final String id;
  final String accountId;
  final String? destinationAccountId;
  final TransactionType type;
  final double amount;
  final TransactionStatus status;
  final String correlationId;
  final String? failureReason;
  final DateTime createdAt;
  final DateTime? processedAt;

  const TransactionModel({
    required this.id,
    required this.accountId,
    this.destinationAccountId,
    required this.type,
    required this.amount,
    required this.status,
    required this.correlationId,
    this.failureReason,
    required this.createdAt,
    this.processedAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    double parseDecimal(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return TransactionModel(
      id: json['id'] as String? ?? '',
      accountId: json['account_id'] as String? ?? '',
      destinationAccountId: json['destination_account_id'] as String?,
      type: TransactionType.fromString(json['type'] as String?),
      amount: parseDecimal(json['amount']),
      status: TransactionStatus.fromString(json['status'] as String?),
      correlationId: json['correlation_id'] as String? ?? '',
      failureReason: json['failure_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      processedAt: json['processed_at'] != null
          ? DateTime.tryParse(json['processed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'account_id': accountId,
        'destination_account_id': destinationAccountId,
        'type': type.value,
        'amount': amount.toStringAsFixed(2),
        'status': status.value,
        'correlation_id': correlationId,
        if (failureReason != null) 'failure_reason': failureReason,
        'created_at': createdAt.toIso8601String(),
        if (processedAt != null) 'processed_at': processedAt!.toIso8601String(),
      };

  TransactionModel copyWith({
    String? id,
    String? accountId,
    String? destinationAccountId,
    TransactionType? type,
    double? amount,
    TransactionStatus? status,
    String? correlationId,
    String? failureReason,
    DateTime? createdAt,
    DateTime? processedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      correlationId: correlationId ?? this.correlationId,
      failureReason: failureReason ?? this.failureReason,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }
}
