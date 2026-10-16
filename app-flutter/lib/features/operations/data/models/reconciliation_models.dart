class LedgerReconciliationMetrics {
  final double totalDebit;
  final double totalCredit;
  final double netDiscrepancy;
  final bool isBalanced;
  final int totalLedgerEntries;

  const LedgerReconciliationMetrics({
    required this.totalDebit,
    required this.totalCredit,
    required this.netDiscrepancy,
    required this.isBalanced,
    required this.totalLedgerEntries,
  });

  factory LedgerReconciliationMetrics.fromJson(Map<String, dynamic> json) {
    double parse(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return LedgerReconciliationMetrics(
      totalDebit: parse(json['total_debit']),
      totalCredit: parse(json['total_credit']),
      netDiscrepancy: parse(json['net_discrepancy']),
      isBalanced: json['is_balanced'] as bool? ?? true,
      totalLedgerEntries: json['total_ledger_entries'] as int? ?? 0,
    );
  }
}

class TransactionIntegrityMetrics {
  final int totalTransactions;
  final int processedTransactions;
  final int pendingTransactions;
  final int failedTransactions;
  final int orphanTransactions;

  const TransactionIntegrityMetrics({
    required this.totalTransactions,
    required this.processedTransactions,
    required this.pendingTransactions,
    required this.failedTransactions,
    required this.orphanTransactions,
  });

  factory TransactionIntegrityMetrics.fromJson(Map<String, dynamic> json) {
    return TransactionIntegrityMetrics(
      totalTransactions: json['total_transactions'] as int? ?? 0,
      processedTransactions: json['processed_transactions'] as int? ?? 0,
      pendingTransactions: json['pending_transactions'] as int? ?? 0,
      failedTransactions: json['failed_transactions'] as int? ?? 0,
      orphanTransactions: json['orphan_transactions'] as int? ?? 0,
    );
  }
}

class AccountIntegrityMetrics {
  final int totalAccounts;
  final int activeAccounts;
  final int blockedAccounts;
  final int negativeBalanceAccounts;
  final double totalCustodyBalance;
  final int discrepantAccountsCount;

  const AccountIntegrityMetrics({
    required this.totalAccounts,
    required this.activeAccounts,
    required this.blockedAccounts,
    required this.negativeBalanceAccounts,
    required this.totalCustodyBalance,
    required this.discrepantAccountsCount,
  });

  factory AccountIntegrityMetrics.fromJson(Map<String, dynamic> json) {
    double parse(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return AccountIntegrityMetrics(
      totalAccounts: json['total_accounts'] as int? ?? 0,
      activeAccounts: json['active_accounts'] as int? ?? 0,
      blockedAccounts: json['blocked_accounts'] as int? ?? 0,
      negativeBalanceAccounts: json['negative_balance_accounts'] as int? ?? 0,
      totalCustodyBalance: parse(json['total_custody_balance']),
      discrepantAccountsCount: json['discrepant_accounts_count'] as int? ?? 0,
    );
  }
}

class BatchJobSummary {
  final String? lastReconciliationDate;
  final String? lastReconciliationStatus;
  final int reconciledToday;
  final int divergentToday;
  final int runningJobs;

  const BatchJobSummary({
    this.lastReconciliationDate,
    this.lastReconciliationStatus,
    required this.reconciledToday,
    required this.divergentToday,
    required this.runningJobs,
  });

  factory BatchJobSummary.fromJson(Map<String, dynamic> json) {
    return BatchJobSummary(
      lastReconciliationDate: json['last_reconciliation_date'] as String?,
      lastReconciliationStatus: json['last_reconciliation_status'] as String?,
      reconciledToday: json['reconciled_today'] as int? ?? 0,
      divergentToday: json['divergent_today'] as int? ?? 0,
      runningJobs: json['running_jobs'] as int? ?? 0,
    );
  }
}

class OperationalDashboardData {
  final String systemStatus;
  final String timestamp;
  final LedgerReconciliationMetrics ledger;
  final TransactionIntegrityMetrics transactions;
  final AccountIntegrityMetrics accounts;
  final BatchJobSummary batch;

  const OperationalDashboardData({
    required this.systemStatus,
    required this.timestamp,
    required this.ledger,
    required this.transactions,
    required this.accounts,
    required this.batch,
  });

  factory OperationalDashboardData.fromJson(Map<String, dynamic> json) {
    return OperationalDashboardData(
      systemStatus: json['system_status'] as String? ?? 'HEALTHY',
      timestamp: json['timestamp'] as String? ?? '',
      ledger: LedgerReconciliationMetrics.fromJson(json['ledger'] as Map<String, dynamic>? ?? {}),
      transactions: TransactionIntegrityMetrics.fromJson(json['transactions'] as Map<String, dynamic>? ?? {}),
      accounts: AccountIntegrityMetrics.fromJson(json['accounts'] as Map<String, dynamic>? ?? {}),
      batch: BatchJobSummary.fromJson(json['batch'] as Map<String, dynamic>? ?? {}),
    );
  }
}
