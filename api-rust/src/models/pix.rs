use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use time::OffsetDateTime;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq, Eq)]
#[sqlx(type_name = "varchar", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum PixKeyType {
    Cpf,
    Email,
    Phone,
    Random,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct PixKey {
    pub id: Uuid,
    pub account_id: Uuid,
    pub key_type: String, // Or PixKeyType if enum is mapped perfectly, but String is safer for simple insert/selects sometimes without extra macro config
    pub key_value: String,
    #[serde(with = "time::serde::rfc3339")]
    pub created_at: OffsetDateTime,
}

#[derive(Debug, Deserialize)]
pub struct CreatePixKeyRequest {
    pub key_type: PixKeyType,
    pub key_value: String,
}

#[derive(Debug, Deserialize)]
pub struct PixPaymentRequest {
    pub key: String,
    pub amount: Decimal,
    pub description: Option<String>,
    pub correlation_id: Uuid,
}

#[derive(Debug, Serialize)]
pub struct PixQrResponse {
    pub payload: String,
}
