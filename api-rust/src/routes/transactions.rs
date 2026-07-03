use axum::{
    extract::{Path, State},
    http::StatusCode,
    routing::{get, post},
    Extension, Json, Router,
};
use std::sync::Arc;
use uuid::Uuid;

use crate::{
    errors::AppResult,
    middleware::auth::Claims,
    models::transaction::{CreateTransactionRequest, Transaction},
    services::transaction_service,
    AppState,
};

pub fn router() -> Router<Arc<AppState>> {
    Router::new()
        .route("/transactions", post(create_transaction))
        .route("/transactions/:id", get(get_transaction))
}

/// Retorna 202 Accepted — o processamento é assíncrono via fila
async fn create_transaction(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
    Json(body): Json<CreateTransactionRequest>,
) -> AppResult<(StatusCode, Json<Transaction>)> {
    let tx =
        transaction_service::create(&state.db, &state.amqp_channel, body, claims.sub).await?;
    Ok((StatusCode::ACCEPTED, Json(tx)))
}

async fn get_transaction(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<Uuid>,
) -> AppResult<Json<Transaction>> {
    let tx = transaction_service::find_by_id_and_owner(&state.db, id, claims.sub).await?;
    Ok(Json(tx))
}
