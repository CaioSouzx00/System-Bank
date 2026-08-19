use anyhow::Result;
use axum::{Extension, Router};
use lapin::{Connection, ConnectionProperties};
use sqlx::postgres::PgPoolOptions;
use std::env;
use std::sync::Arc;
use tokio::net::TcpListener;

pub mod errors;
pub mod middleware;
pub mod models;
pub mod queue;
pub mod routes;
pub mod services;
pub mod telemetry;
pub mod tls;

pub struct AppState {
    pub db: sqlx::PgPool,
    pub amqp_channel: lapin::Channel,
}

#[tokio::main]
async fn main() -> Result<()> {
    telemetry::init_telemetry();

    // 1. Conexão com o Banco de Dados (PostgreSQL)
    let database_url = env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://bankuser:bankpass@localhost:5432/system_bank".to_string());
    
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await?;

    // 2. Conexão com RabbitMQ
    let rabbitmq_url = env::var("RABBITMQ_URL")
        .unwrap_or_else(|_| "amqp://guest:guest@localhost:5672/%2f".to_string());

    let amqp_conn = Connection::connect(&rabbitmq_url, ConnectionProperties::default()).await?;
    let amqp_channel = amqp_conn.create_channel().await?;

    // 3. Declarar Filas
    queue::publisher::declare_queues(&amqp_channel).await?;

    // 4. Iniciar Consumidor de Processados
    let pool_clone = pool.clone();
    let amqp_channel_clone = amqp_conn.create_channel().await?;
    tokio::spawn(async move {
        if let Err(e) = queue::consumer::consume_transactions_processed(pool_clone, amqp_channel_clone).await {
            tracing::error!("Consumer failed: {:?}", e);
        }
    });

    // 5. AppState
    let state = Arc::new(AppState {
        db: pool,
        amqp_channel,
    });

    // 6. Rotas
    let app = Router::new()
        .nest("/health", routes::health::router())
        .nest("/accounts", routes::accounts::router())
        .nest("/transactions", routes::transactions::router())
        .nest("/pix", routes::pix::router())
        .nest("/internal", routes::internal::router())
        .with_state(state)
        // Global middleware
        .layer(axum::middleware::from_fn(middleware::tracing::tracing_middleware))
        .layer(axum::middleware::from_fn(middleware::rate_limit::rate_limiter));

    // 7. Servidor
    let port = env::var("PORT").unwrap_or_else(|_| "8080".to_string());
    let addr = format!("0.0.0.0:{}", port).parse::<std::net::SocketAddr>()?;
    tracing::info!("Server configured for {}", addr);

    if let Some(tls_config) = tls::load_rustls_config().await? {
        tracing::info!("Starting server WITH mTLS on {}", addr);
        axum_server::bind_rustls(addr, tls_config)
            .serve(app.into_make_service())
            .await?;
    } else {
        tracing::warn!("Starting server WITHOUT mTLS (missing certs in env) on {}", addr);
        let listener = TcpListener::bind(&addr).await?;
        axum::serve(listener, app).await?;
    }

    Ok(())
}
