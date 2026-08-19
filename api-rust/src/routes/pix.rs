use std::sync::Arc;

use axum::{
    extract::{Path, State},
    routing::{delete, get, post},
    Extension, Json, Router,
};
use uuid::Uuid;

use crate::{
    errors::AppResult,
    middleware::auth::Claims,
    models::pix::{CreatePixKeyRequest, PixKey, PixPaymentRequest, PixQrResponse},
    models::transaction::Transaction,
    services::pix_service,
    AppState,
};

pub fn router() -> Router<Arc<AppState>> {
    Router::new()
        .route("/keys", post(register_key).get(list_keys))
        .route("/keys/:id", delete(remove_key))
        .route("/payment", post(initiate_payment))
        .route("/qrcode/:key", get(generate_qr_code))
}

async fn register_key(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
    Json(req): Json<CreatePixKeyRequest>,
) -> AppResult<Json<PixKey>> {
    // Para simplificar, assumimos que a conta de origem será a primeira conta do usuário.
    // Numa implementação real, a requisição poderia especificar de qual conta do usuário a chave pertence.
    let account = crate::services::account_service::list(&state.db, claims.sub)
        .await?
        .into_iter()
        .next()
        .ok_or_else(|| crate::errors::AppError::NotFound("Conta não encontrada para usuário".into()))?;

    let key = pix_service::register_key(&state.db, account.id, req).await?;
    Ok(Json(key))
}

async fn list_keys(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
) -> AppResult<Json<Vec<PixKey>>> {
    let account = crate::services::account_service::list(&state.db, claims.sub)
        .await?
        .into_iter()
        .next()
        .ok_or_else(|| crate::errors::AppError::NotFound("Conta não encontrada para usuário".into()))?;

    let keys = pix_service::list_keys(&state.db, account.id).await?;
    Ok(Json(keys))
}

async fn remove_key(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<Uuid>,
) -> AppResult<()> {
    let account = crate::services::account_service::list(&state.db, claims.sub)
        .await?
        .into_iter()
        .next()
        .ok_or_else(|| crate::errors::AppError::NotFound("Conta não encontrada para usuário".into()))?;

    pix_service::remove_key(&state.db, id, account.id).await?;
    Ok(())
}

async fn initiate_payment(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
    Json(req): Json<PixPaymentRequest>,
) -> AppResult<Json<Transaction>> {
    let account = crate::services::account_service::list(&state.db, claims.sub)
        .await?
        .into_iter()
        .next()
        .ok_or_else(|| crate::errors::AppError::NotFound("Conta não encontrada para usuário".into()))?;

    let tx = pix_service::initiate_payment(&state.db, &state.amqp_channel, claims.sub, account.id, req).await?;
    Ok(Json(tx))
}

async fn generate_qr_code(
    Path(key): Path<String>,
) -> AppResult<Json<PixQrResponse>> {
    let payload = pix_service::generate_qr_code(&key);
    Ok(Json(PixQrResponse { payload }))
}
