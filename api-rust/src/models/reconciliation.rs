use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LedgerReconciliationMetrics {
    pub total_debit: Decimal,
    pub total_credit: Decimal,
    pub net_discrepancy: Decimal,
    pub is_balanced: bool,
    pub total_ledger_entries: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TransactionIntegrityMetrics {
    pub total_transactions: i64,
    pub processed_transactions: i64,
    pub pending_transactions: i64,
    pub failed_transactions: i64,
    pub orphan_transactions: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AccountIntegrityMetrics {
    pub total_accounts: i64,
    pub active_accounts: i64,
    pub blocked_accounts: i64,
    pub negative_balance_accounts: i64,
    pub total_custody_balance: Decimal,
    pub discrepant_accounts_count: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatchJobSummary {
    pub last_reconciliation_date: Option<String>,
    pub last_reconciliation_status: Option<String>,
    pub reconciled_today: i64,
    pub divergent_today: i64,
    pub running_jobs: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OperationalDashboardData {
    pub system_status: String,
    pub timestamp: String,
    pub ledger: LedgerReconciliationMetrics,
    pub transactions: TransactionIntegrityMetrics,
    pub accounts: AccountIntegrityMetrics,
    pub batch: BatchJobSummary,
}
