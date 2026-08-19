use lapin::{
    options::{BasicAckOptions, BasicConsumeOptions, BasicNackOptions, BasicPublishOptions},
    types::FieldTable,
    BasicProperties, Channel,
};
use sqlx::PgPool;
use tracing::{error, info, instrument, warn};
use futures_util::stream::StreamExt;
use std::time::Duration;
use opentelemetry::propagation::Extractor;
use tracing_opentelemetry::OpenTelemetrySpanExt;
use tracing::Instrument;

struct HeaderExtractor<'a>(&'a FieldTable);

impl<'a> Extractor for HeaderExtractor<'a> {
    fn get(&self, key: &str) -> Option<&str> {
        if let Some(val) = self.0.inner().get(key) {
            if let lapin::types::AMQPValue::LongString(s) = val {
                return Some(s.as_str());
            }
        }
        None
    }

    fn keys(&self) -> Vec<&str> {
        self.0.inner().keys().map(|k| k.as_str()).collect()
    }
}

use crate::models::transaction::{Transaction, TransactionStatus};
use crate::queue::publisher::{QUEUE_TRANSACTIONS_FAILED, QUEUE_TRANSACTIONS_PROCESSED};

pub async fn consume_transactions_processed(pool: PgPool, channel: Channel) -> anyhow::Result<()> {
    let mut consumer = channel
        .basic_consume(
            QUEUE_TRANSACTIONS_PROCESSED,
            "processed_consumer",
            BasicConsumeOptions::default(),
            FieldTable::default(),
        )
        .await?;

    info!("Iniciando consumer para {}", QUEUE_TRANSACTIONS_PROCESSED);

    while let Some(delivery) = consumer.next().await {
        if let Ok(delivery) = delivery {
            let tx_id = delivery.properties.message_id().clone();
            
            let parent_context = opentelemetry::global::get_text_map_propagator(|propagator| {
                if let Some(headers) = delivery.properties.headers() {
                    propagator.extract(&HeaderExtractor(headers))
                } else {
                    opentelemetry::Context::new()
                }
            });

            let span = tracing::info_span!(
                "rabbitmq.consume",
                queue = QUEUE_TRANSACTIONS_PROCESSED,
                message_id = ?tx_id
            );
            span.set_parent(parent_context);

            async {
                let mut success = false;
                // 3 tentativas de processamento
                for attempt in 1..=3 {
                    match process_message(&pool, &delivery.data).await {
                        Ok(_) => {
                            success = true;
                            break;
                        }
                        Err(e) => {
                            warn!(
                                attempt,
                                message_id = ?tx_id,
                                error = %e,
                                "Erro ao processar transação"
                            );
                            if attempt < 3 {
                                tokio::time::sleep(Duration::from_millis(500)).await;
                            }
                        }
                    }
                }

                if success {
                    // Reconhece (ACK) somente após atualização confirmada no banco
                    if let Err(e) = delivery.ack(BasicAckOptions::default()).await {
                        error!(error = %e, "Erro ao fazer ACK da mensagem");
                    } else {
                        info!(message_id = ?tx_id, "Mensagem processada e ACK enviada");
                    }
                } else {
                    // Rejeita (NACK com requeue=false) após 3 tentativas -> dead-letter
                    if let Err(e) = delivery.nack(BasicNackOptions { multiple: false, requeue: false }).await {
                        error!(error = %e, "Erro ao fazer NACK da mensagem");
                    } else {
                        error!(message_id = ?tx_id, "Mensagem rejeitada (NACK requeue=false) e enviada para DLQ");
                    }
                    
                    // Em caso de falha, publicar em transactions.failed
                    if let Ok(payload) = serde_json::from_slice::<Transaction>(&delivery.data) {
                        publish_to_failed(&channel, &payload).await;
                    }
                }
            }.instrument(span).await;
        }
    }

    Ok(())
}

#[instrument(skip(pool, data))]
async fn process_message(pool: &PgPool, data: &[u8]) -> anyhow::Result<()> {
    // 1. Deserializa
    let tx: Transaction = serde_json::from_slice(data)?;

    // 2. Atualiza transactions.status = 'PROCESSED' e processed_at = NOW()
    let result = sqlx::query!(
        r#"
        UPDATE transactions 
        SET status = 'PROCESSED', processed_at = NOW() 
        WHERE id = $1 AND status != 'PROCESSED'
        "#,
        tx.id
    )
    .execute(pool)
    .await?;

    if result.rows_affected() == 0 {
        info!(transaction_id = %tx.id, "Transação já processada ou não encontrada");
    } else {
        info!(transaction_id = %tx.id, "Transação atualizada para PROCESSED no banco");
        
        // 3. Chamar webhook/notificação (stub)
        call_webhook(&tx).await?;
    }

    Ok(())
}

#[instrument(skip(tx))]
async fn call_webhook(tx: &Transaction) -> anyhow::Result<()> {
    info!(transaction_id = %tx.id, "Chamando webhook de notificação (stub)...");
    // Aqui seria implementada a chamada HTTP real para o webhook
    info!(transaction_id = %tx.id, "Webhook chamado com sucesso");
    Ok(())
}

#[instrument(skip(channel, tx))]
async fn publish_to_failed(channel: &Channel, tx: &Transaction) {
    let mut tx_failed = tx.clone();
    tx_failed.status = TransactionStatus::Failed;
    
    if let Ok(payload) = serde_json::to_vec(&tx_failed) {
        let result = channel
            .basic_publish(
                "",
                QUEUE_TRANSACTIONS_FAILED,
                BasicPublishOptions::default(),
                &payload,
                BasicProperties::default()
                    .with_delivery_mode(2)
                    .with_message_id(tx.correlation_id.to_string().into()),
            )
            .await;
            
        if let Err(e) = result {
            error!(error = %e, transaction_id = %tx.id, "Erro ao publicar na fila transactions.failed");
        } else {
            info!(transaction_id = %tx.id, "Transação publicada na fila transactions.failed");
        }
    }
}
