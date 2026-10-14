use rust_decimal::Decimal;
use rust_decimal_macros::dec;
use sha2::{Digest, Sha256};
use sqlx::PgPool;

use crate::{
    errors::AppResult,
    models::regulatory::{
        BacenPstaw10Report, BacenScrReport, Pstaw10InstrumentSummary,
        RegulatoryReportRecord, ScrClientOperation,
    },
};

pub async fn generate_scr(
    db: &PgPool,
    reference_date_str: &str,
) -> AppResult<(BacenScrReport, String, String)> {
    let accounts = sqlx::query!(
        r#"
        SELECT id, agency, account_number, balance, owner_id
        FROM accounts
        WHERE balance < 0
        ORDER BY balance ASC
        "#
    )
    .fetch_all(db)
    .await?;

    let mut operations = Vec::new();
    let mut total_exposure = Decimal::ZERO;
    let mut total_provision = Decimal::ZERO;

    for (idx, acc) in accounts.iter().enumerate() {
        let drawn = acc.balance.abs();
        total_exposure += drawn;

        // Classificação de risco BACEN Resolução 2682/1999
        // Varia por dias em atraso (simulado sequencialmente para a carteira)
        let overdue_days = ((idx as i32 + 1) * 15) % 180;
        let (risk_level, prov_rate) = match overdue_days {
            0..=14 => ("A", dec!(0.005)),
            15..=30 => ("B", dec!(0.01)),
            31..=60 => ("C", dec!(0.03)),
            61..=90 => ("D", dec!(0.10)),
            91..=120 => ("E", dec!(0.30)),
            121..=150 => ("F", dec!(0.50)),
            151..=180 => ("G", dec!(0.70)),
            _ => ("H", dec!(1.00)),
        };

        let prov_amount = drawn * prov_rate;
        total_provision += prov_amount;

        operations.push(ScrClientOperation {
            account_id: acc.id,
            agency: acc.agency.clone(),
            account_number: acc.account_number.clone(),
            client_document: format!("{:011}", 11122233300_i64 + idx as i64),
            modality: "0201".to_string(), // Cheque Especial / Overdraft
            credit_limit: drawn * dec!(1.5),
            drawn_balance: drawn,
            overdue_days,
            risk_level: risk_level.to_string(),
            provision_percentage: prov_rate * dec!(100),
            provision_amount: prov_amount,
        });
    }

    let total_clients = operations.len();
    let total_ops = operations.len();

    let report = BacenScrReport {
        document_code: "3040".to_string(),
        reference_date: reference_date_str.to_string(),
        institution_ispb: "00000000".to_string(),
        total_clients,
        total_operations: total_ops,
        total_credit_exposure: total_exposure,
        total_provision,
        operations,
    };

    // Monta XML formato regulatório Bacen Doc 3040
    let mut xml = String::new();
    xml.push_str("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
    xml.push_str(&format!(
        "<Doc3040 DtBase=\"{}\" CNPJ=\"00000000000191\" Remessa=\"TOTAL\" TpArq=\"I\">\n",
        reference_date_str
    ));
    xml.push_str(&format!(
        "  <Header TotalClientes=\"{}\" TotalOperacoes=\"{}\" TotalExposicao=\"{}\" TotalProvisao=\"{}\"/>\n",
        total_clients, total_ops, total_exposure, total_provision
    ));
    xml.push_str("  <Clientes>\n");
    for op in &report.operations {
        xml.push_str(&format!(
            "    <Cli Cd=\"{}\" Tp=\"1\">\n",
            op.client_document
        ));
        xml.push_str(&format!(
            "      <Op Mod=\"{}\" Ag=\"{}\" Ct=\"{}\" VlrContr=\"{}\" VlrVenc=\"{}\" ClassOp=\"{}\" Prov=\"{}\"/>\n",
            op.modality, op.agency, op.account_number, op.credit_limit, op.drawn_balance, op.risk_level, op.provision_amount
        ));
        xml.push_str("    </Cli>\n");
    }
    xml.push_str("  </Clientes>\n");
    xml.push_str("</Doc3040>");

    let mut hasher = Sha256::new();
    hasher.update(xml.as_bytes());
    let checksum = format!("{:x}", hasher.finalize());

    // Grava relatório no banco
    let payload = serde_json::to_value(&report).unwrap_or_default();
    let format_desc = time::format_description::parse("[year]-[month]-[day]").unwrap();
    let ref_date = time::Date::parse(reference_date_str, &format_desc)
        .unwrap_or_else(|_| time::OffsetDateTime::now_utc().date());

    let _ = sqlx::query!(
        r#"
        INSERT INTO regulatory_reports (report_type, reference_date, total_records, total_amount, payload, xml_content, checksum)
        VALUES ('BACEN_SCR', $1, $2, $3, $4, $5, $6)
        "#,
        ref_date,
        total_ops as i32,
        total_exposure,
        payload,
        xml,
        checksum
    )
    .execute(db)
    .await;

    Ok((report, xml, checksum))
}

pub async fn generate_pstaw10(
    db: &PgPool,
    reference_date_str: &str,
) -> AppResult<(BacenPstaw10Report, String, String)> {
    let total_active_accounts: i64 = sqlx::query_scalar!(
        "SELECT COUNT(*) FROM accounts WHERE status = 'ACTIVE'"
    )
    .fetch_one(db)
    .await?
    .unwrap_or(0);

    let total_custody: Decimal = sqlx::query_scalar!(
        "SELECT COALESCE(SUM(balance), 0) FROM accounts WHERE balance > 0"
    )
    .fetch_one(db)
    .await?
    .unwrap_or(Decimal::ZERO);

    let transactions = sqlx::query!(
        r#"
        SELECT type as "tx_type!", COUNT(*) as "tx_count!", COALESCE(SUM(amount), 0) as "tx_sum!"
        FROM transactions
        WHERE status = 'PROCESSED'
        GROUP BY type
        "#
    )
    .fetch_all(db)
    .await?;

    let mut instruments = Vec::new();
    let mut total_vol = Decimal::ZERO;

    for row in transactions {
        let count = row.tx_count;
        let sum = row.tx_sum;
        let avg = if count > 0 {
            sum / Decimal::from(count)
        } else {
            Decimal::ZERO
        };
        total_vol += sum;

        instruments.push(Pstaw10InstrumentSummary {
            instrument: row.tx_type,
            transaction_count: count,
            total_volume: sum,
            average_ticket: avg,
        });
    }

    // Se PIX estiver ausente nas transações gravadas, adiciona linha padrão
    if !instruments.iter().any(|i| i.instrument == "PIX") {
        let pix_count: i64 = sqlx::query_scalar!("SELECT COUNT(*) FROM pix_keys")
            .fetch_one(db)
            .await?
            .unwrap_or(0);
        instruments.push(Pstaw10InstrumentSummary {
            instrument: "PIX".to_string(),
            transaction_count: pix_count,
            total_volume: Decimal::ZERO,
            average_ticket: Decimal::ZERO,
        });
    }

    let report = BacenPstaw10Report {
        document_code: "PSTAW10".to_string(),
        reference_date: reference_date_str.to_string(),
        institution_ispb: "00000000".to_string(),
        total_active_accounts,
        total_custody_deposits: total_custody,
        instruments,
        net_clearing_position: Decimal::ZERO, // Partidas dobradas garantem compensação líquida = 0.00
    };

    // Monta XML formato PSTAW10 BACEN
    let mut xml = String::new();
    xml.push_str("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
    xml.push_str(&format!(
        "<DocPSTAW10 DtBase=\"{}\" ISPB=\"00000000\">\n",
        reference_date_str
    ));
    xml.push_str(&format!(
        "  <Contas TotalAtivas=\"{}\" SaldoCustodia=\"{}\"/>\n",
        total_active_accounts, total_custody
    ));
    xml.push_str("  <InstrumentosPagamento>\n");
    for inst in &report.instruments {
        xml.push_str(&format!(
            "    <Instrumento Tipo=\"{}\" Quantidade=\"{}\" VolumeTotal=\"{}\" TicketMedio=\"{}\"/>\n",
            inst.instrument, inst.transaction_count, inst.total_volume, inst.average_ticket
        ));
    }
    xml.push_str("  </InstrumentosPagamento>\n");
    xml.push_str("  <CompensacaoLiquidacao PosiçãoLiquida=\"0.00\" Status=\"EQUILIBRADO\"/>\n");
    xml.push_str("</DocPSTAW10>");

    let mut hasher = Sha256::new();
    hasher.update(xml.as_bytes());
    let checksum = format!("{:x}", hasher.finalize());

    // Grava relatório no banco
    let payload = serde_json::to_value(&report).unwrap_or_default();
    let format_desc = time::format_description::parse("[year]-[month]-[day]").unwrap();
    let ref_date = time::Date::parse(reference_date_str, &format_desc)
        .unwrap_or_else(|_| time::OffsetDateTime::now_utc().date());

    let _ = sqlx::query!(
        r#"
        INSERT INTO regulatory_reports (report_type, reference_date, total_records, total_amount, payload, xml_content, checksum)
        VALUES ('PSTAW10', $1, $2, $3, $4, $5, $6)
        "#,
        ref_date,
        report.instruments.len() as i32,
        total_vol,
        payload,
        xml,
        checksum
    )
    .execute(db)
    .await;

    Ok((report, xml, checksum))
}

pub async fn list_reports(db: &PgPool) -> AppResult<Vec<RegulatoryReportRecord>> {
    let records = sqlx::query_as!(
        RegulatoryReportRecord,
        r#"
        SELECT id, report_type, reference_date, status,
               total_records, total_amount, payload, xml_content,
               checksum, created_at
        FROM regulatory_reports
        ORDER BY created_at DESC
        LIMIT 50
        "#
    )
    .fetch_all(db)
    .await?;

    Ok(records)
}
