enum AccountStatus {
  active('ACTIVE', 'Ativa'),
  blocked('BLOCKED', 'Bloqueada'),
  closed('CLOSED', 'Encerrada');

  final String value;
  final String label;

  const AccountStatus(this.value, this.label);

  static AccountStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'BLOCKED':
        return AccountStatus.blocked;
      case 'CLOSED':
        return AccountStatus.closed;
      case 'ACTIVE':
      default:
        return AccountStatus.active;
    }
  }

  bool get isActive => this == AccountStatus.active;
  bool get isBlocked => this == AccountStatus.blocked;
}

class BankAccount {
  final String id;
  final String agency;
  final String accountNumber;
  final String ownerId;
  final double balance;
  final AccountStatus status;
  final DateTime createdAt;

  const BankAccount({
    required this.id,
    required this.agency,
    required this.accountNumber,
    required this.ownerId,
    required this.balance,
    required this.status,
    required this.createdAt,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as String? ?? '',
      agency: json['agency'] as String? ?? '0001',
      accountNumber: json['account_number'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      balance: _parseDecimal(json['balance']),
      status: AccountStatus.fromString(json['status'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static double _parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'agency': agency,
        'account_number': accountNumber,
        'owner_id': ownerId,
        'balance': balance,
        'status': status.value,
        'created_at': createdAt.toIso8601String(),
      };

  BankAccount copyWith({
    String? id,
    String? agency,
    String? accountNumber,
    String? ownerId,
    double? balance,
    AccountStatus? status,
    DateTime? createdAt,
  }) {
    return BankAccount(
      id: id ?? this.id,
      agency: agency ?? this.agency,
      accountNumber: accountNumber ?? this.accountNumber,
      ownerId: ownerId ?? this.ownerId,
      balance: balance ?? this.balance,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get formattedAccount => 'Agência $agency • Conta $accountNumber';
}
