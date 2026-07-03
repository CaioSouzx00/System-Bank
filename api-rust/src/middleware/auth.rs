use axum::{
    extract::{Request, State},
    middleware::Next,
    response::Response,
};
use jsonwebtoken::{decode, DecodingKey, Validation};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use uuid::Uuid;

use crate::{errors::AppError, AppState};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Claims {
    pub sub: Uuid,    // user_id
    pub role: String, // CLIENT | OPERATOR | ADMIN
    pub exp: usize,
    pub iat: usize,
}

/// Extrai e valida o JWT do header Authorization: Bearer <token>
/// Injeta `Claims` no request para uso downstream
pub async fn require_auth(
    State(state): State<Arc<AppState>>,
    mut req: Request,
    next: Next,
) -> Result<Response, AppError> {
    let token = req
        .headers()
        .get("Authorization")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.strip_prefix("Bearer "))
        .ok_or(AppError::Unauthorized)?;

    let key = DecodingKey::from_secret(state.config.jwt_secret.as_bytes());
    let token_data = decode::<Claims>(token, &key, &Validation::default())
        .map_err(|_| AppError::Unauthorized)?;

    req.extensions_mut().insert(token_data.claims);
    Ok(next.run(req).await)
}
