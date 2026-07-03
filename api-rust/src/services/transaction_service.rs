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
