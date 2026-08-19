use lapin::Channel;
use sqlx::PgPool;
use uuid::Uuid;

use crate::{
    errors::{AppError, AppResult},
    models::{
        pix::{CreatePixKeyRequest, PixKey, PixPaymentRequest},
        transaction::{CreateTransactionRequest, Transaction, TransactionType},
    },
    services::transaction_service,
};

pub async fn register_key(
    db: &PgPool,
    account_id: Uuid,
    req: CreatePixKeyRequest,
) -> AppResult<PixKey> {
    let key_type_str = match req.key_type {
        crate::models::pix::PixKeyType::Cpf => "CPF",
        crate::models::pix::PixKeyType::Email => "EMAIL",
        crate::models::pix::PixKeyType::Phone => "PHONE",
        crate::models::pix::PixKeyType::Random => "RANDOM",
    };

    let pix_key = sqlx::query_as!(
        PixKey,
        r#"INSERT INTO pix_keys (account_id, key_type, key_value)
           VALUES ($1, $2, $3)
           RETURNING id, account_id, key_type, key_value, created_at"#,
        account_id,
        key_type_str,
        req.key_value,
    )
    .fetch_one(db)
    .await
    .map_err(|e| match e {
        sqlx::Error::Database(ref dbe) if dbe.constraint() == Some("pix_keys_key_value_key") => {
            AppError::Conflict("Chave PIX já cadastrada".into())
        }
        _ => AppError::Database(e),
    })?;

    Ok(pix_key)
}

pub async fn list_keys(db: &PgPool, account_id: Uuid) -> AppResult<Vec<PixKey>> {
    let keys = sqlx::query_as!(
        PixKey,
        r#"SELECT id, account_id, key_type, key_value, created_at
           FROM pix_keys
           WHERE account_id = $1
           ORDER BY created_at DESC"#,
        account_id
    )
    .fetch_all(db)
    .await?;

    Ok(keys)
}

pub async fn remove_key(db: &PgPool, key_id: Uuid, account_id: Uuid) -> AppResult<()> {
    let result = sqlx::query!(
        r#"DELETE FROM pix_keys WHERE id = $1 AND account_id = $2"#,
        key_id,
        account_id
    )
    .execute(db)
    .await?;

    if result.rows_affected() == 0 {
        return Err(AppError::NotFound("Chave PIX não encontrada".into()));
    }

    Ok(())
}

pub async fn initiate_payment(
    db: &PgPool,
    channel: &Channel,
    user_id: Uuid,
    account_id: Uuid,
    req: PixPaymentRequest,
) -> AppResult<Transaction> {
    // 1. Encontrar a conta de destino pela chave PIX
    let destination_key = sqlx::query!(
        r#"SELECT account_id FROM pix_keys WHERE key_value = $1"#,
        req.key
    )
    .fetch_optional(db)
    .await?
    .ok_or_else(|| AppError::NotFound("Chave PIX de destino não encontrada".into()))?;

    // 2. Montar requisição de transferência e delegar
    let tx_req = CreateTransactionRequest {
        account_id,
        destination_account_id: Some(destination_key.account_id),
        r#type: TransactionType::Transfer,
        amount: req.amount,
        correlation_id: req.correlation_id,
    };

    // Obs: ignorando `description` pois o DB atual de transactions não armazena description.
    
    transaction_service::create(db, channel, tx_req, user_id).await
}

pub fn generate_qr_code(key: &str) -> String {
    // String formatada para simulação do payload EMV QRCPS-MPM padrão BACEN
    // Opcionalmente, pode-se calcular CRC16, mas para simulação, um dummy é suficiente
    let key_len = format!("{:02}", key.len());
    format!("00020126580014br.gov.bcb.pix01{}{KEY}5204000053039865802BR5913Nome do Recebedor6008Brasilia62070503***6304ABCD", key_len, KEY = key)
}
