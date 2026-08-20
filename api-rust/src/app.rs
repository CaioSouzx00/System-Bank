use axum::Router;
use std::sync::Arc;

use crate::{middleware, routes, AppState};

pub fn create_router(state: Arc<AppState>) -> Router {
    // Rotas públicas (sem autenticação)
    let public_routes = Router::new()
        .nest("/health", routes::health::router())
        .nest("/internal", routes::internal::router());

    // Rotas protegidas (exigem JWT válido)
    let protected_routes = Router::new()
        .nest("/accounts", routes::accounts::router())
        .nest("/transactions", routes::transactions::router())
        .nest("/pix", routes::pix::router())
        .route_layer(axum::middleware::from_fn_with_state(
            state.clone(),
            middleware::auth::require_auth,
        ));

    Router::new()
        .merge(public_routes)
        .merge(protected_routes)
        .with_state(state)
        // Middleware global: tracing e rate limit por IP
        .layer(axum::middleware::from_fn(middleware::tracing::tracing_middleware))
        .layer(axum::middleware::from_fn(middleware::rate_limit::ip_rate_limit))
}
