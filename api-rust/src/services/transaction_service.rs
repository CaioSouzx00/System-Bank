use lapin::{options::BasicPublishOptions, BasicProperties, Channel};
use sqlx::PgPool;
use uuid::Uuid;

use crate::{
    errors::{AppError, AppResult},
    models::transaction::{CreateTransactionRequest, Transaction},
    queue::publisher,
};

pub async fn create(
    db: &PgPool,
    channel: &Channel,
    req: CreateTransactionRequest,
    _user_id: Uuid,
) -> AppResult<Transaction> {
    // Idempotência: verifica se correlation_id já existe
    if let Some(existing) = find_by_correlation_id(db, req.correlation_id).await? {
        return Ok(existing);
    }

    let tx = sqlx::query_as!(
        Transaction,
        r#"INSERT INTO transactions
             (id, account_id, destination_account_id, type, amount, status, correlation_id)
           VALUES
             (gen_random_uuid(), $1, $2, $3, $4, 'PENDING', $5)
           RETURNING
             id, account_id, destination_account_id,
             type as "type: _", amount, status as "status: _",
             correlation_id, failure_reason, created_at, processed_at"#,
        req.account_id,
        req.destination_account_id,
        req.r#type as _,
        req.amount,
        req.correlation_id,
    )
    .fetch_one(db)
    .await
    .map_err(|e| match e {
        sqlx::Error::Database(ref dbe) if dbe.constraint() == Some("transactions_correlation_id_key") => {
            AppError::Conflict("Transação com esse correlation_id já existe".into())
        }
        _ => AppError::Database(e),
    })?;

    // Publica na fila — processamento assíncrono pelo worker COBOL
    publisher::publish_transaction_pending(channel, &tx).await?;

    Ok(tx)
}

pub async fn find_by_id_and_owner(db: &PgPool, id: Uuid, owner_id: Uuid) -> AppResult<Transaction> {
    sqlx::query_as!(
        Transaction,
        r#"SELECT t.id, t.account_id, t.destination_account_id,
                  t.type as "type: _", t.amount, t.status as "status: _",
                  t.correlation_id, t.failure_reason, t.created_at, t.processed_at
           FROM transactions t
           JOIN accounts a ON a.id = t.account_id
           WHERE t.id = $1 AND a.owner_id = $2"#,
        id,
        owner_id
    )
    .fetch_optional(db)
    .await?
    .ok_or_else(|| AppError::NotFound("Transação não encontrada".into()))
}

async fn find_by_correlation_id(db: &PgPool, correlation_id: Uuid) -> AppResult<Option<Transaction>> {
    Ok(sqlx::query_as!(
        Transaction,
        r#"SELECT id, account_id, destination_account_id,
                  type as "type: _", amount, status as "status: _",
                  correlation_id, failure_reason, created_at, processed_at
           FROM transactions WHERE correlation_id = $1"#,
        correlation_id
    )
    .fetch_optional(db)
    .await?)
}

pub async fn find_by_account_id_and_date_range(
    db: &PgPool,
    account_id: Uuid,
    owner_id: Uuid,
    from: time::OffsetDateTime,
    to: time::OffsetDateTime,
) -> AppResult<Vec<Transaction>> {
    // 1. Validate if account belongs to owner
    let account_exists = sqlx::query_scalar!(
        r#"SELECT EXISTS(SELECT 1 FROM accounts WHERE id = $1 AND owner_id = $2)"#,
        account_id,
        owner_id
    )
    .fetch_one(db)
    .await?
    .unwrap_or(false);

    if !account_exists {
        return Err(AppError::NotFound("Conta não encontrada".into()));
    }

    // 2. Fetch transactions
    let transactions = sqlx::query_as!(
        Transaction,
        r#"SELECT id, account_id, destination_account_id,
                  type as "type: _", amount, status as "status: _",
                  correlation_id, failure_reason, created_at, processed_at
           FROM transactions
           WHERE account_id = $1 AND created_at >= $2 AND created_at <= $3
           ORDER BY created_at ASC"#,
        account_id,
        from,
        to
    )
    .fetch_all(db)
    .await?;

    Ok(transactions)
}
