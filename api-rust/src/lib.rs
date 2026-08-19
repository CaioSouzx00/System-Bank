pub mod app;
pub mod errors;
pub mod middleware;
pub mod models;
pub mod queue;
pub mod routes;
pub mod services;
pub mod telemetry;
pub mod tls;

// Expose AppState since it's needed by app.rs and main.rs
pub struct AppState {
    pub db: sqlx::PgPool,
    pub amqp_channel: lapin::Channel,
}
