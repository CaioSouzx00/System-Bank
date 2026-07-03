use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use time::OffsetDateTime;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Transaction {
    pub id: Uuid,
    pub account_id: Uuid,
    pub destination_account_id: Option<Uuid>,
    pub r#type: TransactionType,
    pub amount: Decimal,
    pub status: TransactionStatus,
    pub correlation_id: Uuid,
    pub failure_reason: Option<String>,
    #[serde(with = "time::serde::rfc3339")]
    pub created_at: OffsetDateTime,
    #[serde(with = "time::serde::rfc3339::option")]
    pub processed_at: Option<OffsetDateTime>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "varchar", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum TransactionType {
    Debit,
    Credit,
    Transfer,
    Fee,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "varchar", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum TransactionStatus {
    Pending,
    Processed,
    Failed,
    Reversed,
}

#[derive(Debug, Deserialize)]
pub struct CreateTransactionRequest {
    pub account_id: Uuid,
    pub destination_account_id: Option<Uuid>,
    pub r#type: TransactionType,
    /// Nunca use f64 para dinheiro — Decimal garante precisão exata
    pub amount: Decimal,
    /// Chave de idempotência gerada pelo cliente
    pub correlation_id: Uuid,
}
