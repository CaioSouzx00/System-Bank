use anyhow::Result;
use lapin::{
    options::{BasicPublishOptions, QueueDeclareOptions},
    types::{AMQPValue, FieldTable, ShortString},
    BasicProperties, Channel,
};
use opentelemetry::propagation::Injector;
use tracing_opentelemetry::OpenTelemetrySpanExt;

use crate::models::transaction::Transaction;

pub const QUEUE_TRANSACTIONS_PENDING: &str = "transactions.pending";
pub const QUEUE_TRANSACTIONS_PROCESSED: &str = "transactions.processed";
pub const QUEUE_TRANSACTIONS_FAILED: &str = "transactions.failed";
pub const QUEUE_BATCH_DAILY_CLOSING: &str = "batch.daily-closing";
pub const QUEUE_DLQ: &str = "transactions.dlq";

struct HeaderInjector<'a>(&'a mut FieldTable);

impl<'a> Injector for HeaderInjector<'a> {
    fn set(&mut self, key: &str, value: String) {
        self.0.insert(
            ShortString::from(key),
            AMQPValue::LongString(value.into()),
        );
    }
}

/// Declara todas as filas necessárias (idempotente — safe para chamar no boot)
pub async fn declare_queues(channel: &Channel) -> Result<()> {
    let opts = QueueDeclareOptions {
        durable: true,
        ..Default::default()
    };

    let mut dlq_args = FieldTable::default();
    dlq_args.insert(
        "x-dead-letter-exchange".into(),
        lapin::types::AMQPValue::LongString("".into()),
    );
    dlq_args.insert(
        "x-dead-letter-routing-key".into(),
        lapin::types::AMQPValue::LongString(QUEUE_DLQ.into()),
    );

    for queue in [
        QUEUE_TRANSACTIONS_PENDING,
        QUEUE_TRANSACTIONS_FAILED,
        QUEUE_BATCH_DAILY_CLOSING,
        QUEUE_DLQ,
    ] {
        channel
            .queue_declare(queue, opts.clone(), FieldTable::default())
            .await?;
    }

    // Configura transactions.processed com DLQ
    channel
        .queue_declare(
            QUEUE_TRANSACTIONS_PROCESSED,
            opts.clone(),
            dlq_args,
        )
        .await?;

    Ok(())
}

pub async fn publish_transaction_pending(channel: &Channel, tx: &Transaction) -> Result<()> {
    let payload = serde_json::to_vec(tx)?;

    let mut headers = FieldTable::default();
    opentelemetry::global::get_text_map_propagator(|propagator| {
        let context = tracing::Span::current().context();
        propagator.inject_context(&context, &mut HeaderInjector(&mut headers))
    });

    channel
        .basic_publish(
            "",
            QUEUE_TRANSACTIONS_PENDING,
            BasicPublishOptions::default(),
            &payload,
            BasicProperties::default()
                .with_delivery_mode(2) // persistent
                .with_message_id(tx.correlation_id.to_string().into())
                .with_headers(headers),
        )
        .await?
        .await?;

    tracing::info!(
        transaction_id = %tx.id,
        correlation_id = %tx.correlation_id,
        "transação publicada na fila"
    );

    Ok(())
}
