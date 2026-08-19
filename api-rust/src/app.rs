use axum::Router;
use std::sync::Arc;

use crate::{middleware, routes, AppState};

pub fn create_router(state: Arc<AppState>) -> Router {
    Router::new()
        .nest("/health", routes::health::router())
        .nest("/accounts", routes::accounts::router())
        .nest("/transactions", routes::transactions::router())
        .nest("/pix", routes::pix::router())
        .nest("/internal", routes::internal::router())
        .with_state(state)
        // Global middleware
        .layer(axum::middleware::from_fn(middleware::tracing::tracing_middleware))
        .layer(axum::middleware::from_fn(middleware::rate_limit::rate_limiter))
}
