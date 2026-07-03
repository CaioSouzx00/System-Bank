use anyhow::Result;
use lapin::{
    options::{BasicPublishOptions, QueueDeclareOptions},
    types::FieldTable,
    BasicProperties, Channel,
};

use crate::models::transaction::Transaction;

pub const QUEUE_TRANSACTIONS_PENDING: &str = "transactions.pending";
pub const QUEUE_TRANSACTIONS_PROCESSED: &str = "transactions.processed";
pub const QUEUE_TRANSACTIONS_FAILED: &str = "transactions.failed";
pub const QUEUE_BATCH_DAILY_CLOSING: &str = "batch.daily-closing";
pub const QUEUE_DLQ: &str = "transactions.dlq";

/// Declara todas as filas necessárias (idempotente — safe para chamar no boot)
pub async fn declare_queues(channel: &Channel) -> Result<()> {
    let opts = QueueDeclareOptions {
        durable: true,
        ..Default::default()
    };

    for queue in [
        QUEUE_TRANSACTIONS_PENDING,
        QUEUE_TRANSACTIONS_PROCESSED,
        QUEUE_TRANSACTIONS_FAILED,
        QUEUE_BATCH_DAILY_CLOSING,
        QUEUE_DLQ,
    ] {
        channel
            .queue_declare(queue, opts.clone(), FieldTable::default())
            .await?;
    }

    Ok(())
}

/// Publica uma transação pendente na fila para processamento pelo worker COBOL
pub async fn publish_transaction_pending(channel: &Channel, tx: &Transaction) -> Result<()> {
    let payload = serde_json::to_vec(tx)?;

    channel
        .basic_publish(
            "",
            QUEUE_TRANSACTIONS_PENDING,
            BasicPublishOptions::default(),
            &payload,
            BasicProperties::default()
                .with_delivery_mode(2) // persistent
                .with_message_id(tx.correlation_id.to_string().into()),
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
