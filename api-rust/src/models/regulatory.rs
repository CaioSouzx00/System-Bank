use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScrClientOperation {
    pub account_id: Uuid,
    pub agency: String,
    pub account_number: String,
    pub client_document: String,
    pub modality: String,
    pub credit_limit: Decimal,
    pub drawn_balance: Decimal,
    pub overdue_days: i32,
    pub risk_level: String,
    pub provision_percentage: Decimal,
    pub provision_amount: Decimal,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BacenScrReport {
    pub document_code: String,
    pub reference_date: String,
    pub institution_ispb: String,
    pub total_clients: usize,
    pub total_operations: usize,
    pub total_credit_exposure: Decimal,
    pub total_provision: Decimal,
    pub operations: Vec<ScrClientOperation>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Pstaw10InstrumentSummary {
    pub instrument: String,
    pub transaction_count: i64,
    pub total_volume: Decimal,
    pub average_ticket: Decimal,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BacenPstaw10Report {
    pub document_code: String,
    pub reference_date: String,
    pub institution_ispb: String,
    pub total_active_accounts: i64,
    pub total_custody_deposits: Decimal,
    pub instruments: Vec<Pstaw10InstrumentSummary>,
    pub net_clearing_position: Decimal,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RegulatoryReportRecord {
    pub id: Uuid,
    pub report_type: String,
    pub reference_date: time::Date,
    pub status: String,
    pub total_records: i32,
    pub total_amount: Decimal,
    pub payload: serde_json::Value,
    pub xml_content: Option<String>,
    pub checksum: String,
    pub created_at: time::OffsetDateTime,
}

#[derive(Debug, Deserialize)]
pub struct RegulatoryQuery {
    pub date: Option<String>,
    pub format: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct SimulateRegulatoryRequest {
    pub reference_date: String,
    pub report_type: String,
}
