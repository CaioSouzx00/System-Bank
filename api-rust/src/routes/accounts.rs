use axum::{
    extract::{Path, State},
    routing::{get, post},
    Extension, Json, Router,
};
use std::sync::Arc;
use uuid::Uuid;

use crate::{
    errors::AppResult,
    middleware::auth::Claims,
    models::account::{Account, CreateAccountRequest},
    services::account_service,
    AppState,
};

pub fn router() -> Router<Arc<AppState>> {
    Router::new()
        .route("/accounts", get(list_accounts).post(create_account))
        .route("/accounts/:id", get(get_account))
}

async fn list_accounts(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
) -> AppResult<Json<Vec<Account>>> {
    let accounts = account_service::find_by_owner(&state.db, claims.sub).await?;
    Ok(Json(accounts))
}

async fn get_account(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<Uuid>,
) -> AppResult<Json<Account>> {
    let account = account_service::find_by_id_and_owner(&state.db, id, claims.sub).await?;
    Ok(Json(account))
}

async fn create_account(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
    Json(body): Json<CreateAccountRequest>,
) -> AppResult<Json<Account>> {
    let account = account_service::create(&state.db, body, claims.sub).await?;
    Ok(Json(account))
}
