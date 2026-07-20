use anyhow::Result;
use sqlx::postgres::PgPoolOptions;
use std::env;
use std::fs::File;
use std::io::{BufRead, BufReader, Write};
use std::process::Command;
use std::str::FromStr;
use rust_decimal::Decimal;
use uuid::Uuid;

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt::init();

    let database_url = env::var("DATABASE_URL").unwrap_or_else(|_| "postgres://bankuser:bankpass@localhost:5432/system_bank".to_string());
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await?;

    let job = sqlx::query!(
        r#"
        SELECT id, scheduled_for, job_type 
        FROM batch_jobs 
        WHERE job_type IN ('RECONCILIATION', 'FEE_CALC') AND status = 'SCHEDULED'
        ORDER BY scheduled_for ASC LIMIT 1
        "#
    )
    .fetch_optional(&pool)
    .await?;

    if let Some(job) = job {
        let process_date = job.scheduled_for.date().to_string();
        tracing::info!("Iniciando job {} para a data {}", job.job_type, process_date);

        sqlx::query!(
            "UPDATE batch_jobs SET status = 'RUNNING', started_at = NOW() WHERE id = $1",
            job.id
        )
        .execute(&pool)
        .await?;

        // Ensure directories exist
        let _ = std::fs::create_dir_all("../batch-cobol/io/input");
        let _ = std::fs::create_dir_all("../batch-cobol/io/output");

        if job.job_type == "RECONCILIATION" {
            let trans_path = format!("../batch-cobol/io/input/RECONCILIATION-TRANS-{}.dat", process_date);
            let ledger_path = format!("../batch-cobol/io/input/RECONCILIATION-LEDGER-{}.dat", process_date);
            let output_path = format!("../batch-cobol/io/output/RECONCILIATION-{}.out", process_date);

            let mut trans_file = File::create(&trans_path)?;
            let mut ledger_file = File::create(&ledger_path)?;

            let transactions = sqlx::query!(
                "SELECT id, account_id, type, amount FROM transactions WHERE status = 'PROCESSED' AND created_at::date = $1 ORDER BY id",
                job.scheduled_for.date()
            ).fetch_all(&pool).await?;

            for t in transactions {
                let amount_str = format!("{:018.2}", t.amount).replace(".", "");
                writeln!(trans_file, "{:<36} {:<36} {:<10} {:0>18}", t.id.to_string(), t.account_id.to_string(), t.r#type, amount_str)?;
            }

            let ledgers = sqlx::query!(
                "SELECT id, transaction_id, account_id, entry_type, amount FROM ledger_entries WHERE created_at::date = $1 ORDER BY transaction_id, id",
                job.scheduled_for.date()
            ).fetch_all(&pool).await?;

            for l in ledgers {
                let amount_str = format!("{:018.2}", l.amount).replace(".", "");
                writeln!(ledger_file, "{:<36} {:<36} {:<36} {:<10} {:0>18}", l.id.to_string(), l.transaction_id.to_string(), l.account_id.to_string(), l.entry_type, amount_str)?;
            }

            tracing::info!("Arquivos gerados, invocando COBOL RECONCILIATION...");

            let status = Command::new("../batch-cobol/bin/RECONCILIATION")
                .env("TRANS_FILE", &trans_path)
                .env("LEDGER_FILE", &ledger_path)
                .env("OUTPUT_FILE", &output_path)
                .env("PROCESS_DATE", &process_date)
                .status();

            match status {
                Ok(exit_status) => {
                    let code = exit_status.code().unwrap_or(2);
                    let (final_status, error_message) = match code {
                        0 => ("COMPLETED", None),
                        1 => ("FAILED", Some("Divergências encontradas. Consulte o arquivo de saída.")),
                        _ => ("FAILED", Some("Erro fatal na execução do COBOL.")),
                    };

                    sqlx::query!(
                        "UPDATE batch_jobs SET status = $1, finished_at = NOW(), error_message = $2 WHERE id = $3",
                        final_status,
                        error_message,
                        job.id
                    )
                    .execute(&pool)
                    .await?;

                    tracing::info!("Job RECONCILIATION finalizado com código de retorno: {}", code);
                }
                Err(e) => {
                    sqlx::query!(
                        "UPDATE batch_jobs SET status = 'FAILED', finished_at = NOW(), error_message = $1 WHERE id = $2",
                        format!("Erro ao invocar processo COBOL: {}", e),
                        job.id
                    )
                    .execute(&pool)
                    .await?;
                    tracing::error!("Erro ao executar COBOL RECONCILIATION: {}", e);
                }
            }
        } else if job.job_type == "FEE_CALC" {
            let trans_path = format!("../batch-cobol/io/input/FEE-CALC-TRANS-{}.dat", process_date);
            let output_path = format!("../batch-cobol/io/output/FEE-CALC-{}.out", process_date);

            let mut trans_file = File::create(&trans_path)?;

            let transactions = sqlx::query!(
                "SELECT id, account_id, type FROM transactions WHERE status = 'PROCESSED' AND created_at::date = $1 AND type != 'FEE' ORDER BY id",
                job.scheduled_for.date()
            ).fetch_all(&pool).await?;

            for t in transactions {
                writeln!(trans_file, "{:<36} {:<36} {:<10}", t.id.to_string(), t.account_id.to_string(), t.r#type)?;
            }
            drop(trans_file);

            tracing::info!("Arquivos gerados, invocando COBOL FEE-CALC...");

            let status = Command::new("../batch-cobol/bin/FEE-CALC")
                .env("TRANS_FILE", &trans_path)
                .env("OUTPUT_FILE", &output_path)
                .status();

            match status {
                Ok(exit_status) => {
                    let code = exit_status.code().unwrap_or(2);
                    if code == 0 {
                        if let Ok(file) = File::open(&output_path) {
                            let reader = BufReader::new(file);
                            for line_result in reader.lines() {
                                if let Ok(line) = line_result {
                                    let parts: Vec<&str> = line.split(',').collect();
                                    if parts.len() >= 4 {
                                        let account_id = Uuid::parse_str(parts[0].trim()).unwrap_or_default();
                                        let transaction_id = Uuid::parse_str(parts[1].trim()).unwrap_or_default();
                                        let fee_amount_str = parts[2].trim();
                                        
                                        if fee_amount_str.len() == 18 {
                                            let amount_formatted = format!("{}.{}", &fee_amount_str[0..16], &fee_amount_str[16..18]);
                                            if let Ok(fee_amount) = Decimal::from_str(&amount_formatted) {
                                                if fee_amount > Decimal::ZERO {
                                                    let fee_id = Uuid::new_v4();
                                                    let _ = sqlx::query!(
                                                        r#"
                                                        INSERT INTO transactions (id, account_id, type, amount, status, correlation_id, created_at)
                                                        VALUES ($1, $2, 'FEE', $3, 'PROCESSED', $4, NOW())
                                                        "#,
                                                        fee_id,
                                                        account_id,
                                                        fee_amount,
                                                        transaction_id
                                                    ).execute(&pool).await;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        sqlx::query!(
                            "UPDATE batch_jobs SET status = 'COMPLETED', finished_at = NOW() WHERE id = $1",
                            job.id
                        )
                        .execute(&pool)
                        .await?;
                        tracing::info!("Job FEE-CALC finalizado com sucesso.");
                    } else {
                        sqlx::query!(
                            "UPDATE batch_jobs SET status = 'FAILED', finished_at = NOW(), error_message = 'FEE-CALC falhou.' WHERE id = $1",
                            job.id
                        )
                        .execute(&pool)
                        .await?;
                        tracing::error!("FEE-CALC falhou com código: {}", code);
                    }
                }
                Err(e) => {
                    sqlx::query!(
                        "UPDATE batch_jobs SET status = 'FAILED', finished_at = NOW(), error_message = $1 WHERE id = $2",
                        format!("Erro ao invocar processo COBOL: {}", e),
                        job.id
                    )
                    .execute(&pool)
                    .await?;
                    tracing::error!("Erro ao executar COBOL FEE-CALC: {}", e);
                }
            }
        }
    } else {
        tracing::info!("Nenhum job RECONCILIATION ou FEE_CALC pendente.");
    }

    Ok(())
}
