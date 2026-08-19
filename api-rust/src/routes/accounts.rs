use axum::{
    extract::{Path, State, Query},
    routing::{get, post},
    Extension, Json, Router,
    response::IntoResponse,
    http::{header, StatusCode},
};
use std::sync::Arc;
use uuid::Uuid;

use crate::{
    errors::{AppError, AppResult},
    middleware::auth::Claims,
    models::{account::{Account, CreateAccountRequest}, statement::{StatementQuery, StatementFormat}},
    services::{account_service, transaction_service},
    AppState,
};

pub fn router() -> Router<Arc<AppState>> {
    Router::new()
        .route("/accounts", get(list_accounts).post(create_account))
        .route("/accounts/:id", get(get_account))
        .route("/accounts/:id/statement", get(get_statement))
        .route("/accounts/:id/block", post(block_account))
}

async fn list_accounts(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
) -> AppResult<Json<Vec<Account>>> {
    let accounts = account_service::find_by_owner(&state.db, claims.sub).await?;
    Ok(Json(accounts))
}

async fn get_account(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<Uuid>,
) -> AppResult<Json<Account>> {
    let account = account_service::find_by_id_and_owner(&state.db, id, claims.sub).await?;
    Ok(Json(account))
}

async fn create_account(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
    Json(body): Json<CreateAccountRequest>,
) -> AppResult<Json<Account>> {
    let account = account_service::create(&state.db, body, claims.sub).await?;
    Ok(Json(account))
}

async fn block_account(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<Uuid>,
) -> AppResult<Json<Account>> {
    if claims.role != "ADMIN" {
        return Err(crate::errors::AppError::Unauthorized); // Simplification: Using Unauthorized for lack of permissions, unless Forbidden exists.
    }
    
    let account = account_service::block(&state.db, id).await?;
    Ok(Json(account))
}

async fn get_statement(
    State(state): State<Arc<AppState>>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<Uuid>,
    Query(query): Query<StatementQuery>,
) -> AppResult<impl IntoResponse> {
    let format_desc = time::format_description::parse("[year]-[month]-[day]")
        .map_err(|_| AppError::Internal("Formato de data inválido internamente".into()))?;
        
    let from_date = time::Date::parse(&query.from, &format_desc)
        .map_err(|_| AppError::BadRequest("Data 'from' inválida. Use YYYY-MM-DD".into()))?
        .with_hms(0, 0, 0).unwrap()
        .assume_utc();
        
    let to_date = time::Date::parse(&query.to, &format_desc)
        .map_err(|_| AppError::BadRequest("Data 'to' inválida. Use YYYY-MM-DD".into()))?
        .with_hms(23, 59, 59).unwrap()
        .assume_utc();
        
    // Validar intervalo de 90 dias no máximo
    if (to_date - from_date).whole_days() > 90 {
        return Err(AppError::BadRequest("O intervalo não pode ser maior que 90 dias".into()));
    }
    
    if from_date > to_date {
        return Err(AppError::BadRequest("A data 'from' não pode ser posterior a 'to'".into()));
    }

    let transactions = transaction_service::find_by_account_id_and_date_range(&state.db, id, claims.sub, from_date, to_date).await?;

    match query.format {
        StatementFormat::Json => {
            Ok((StatusCode::OK, Json(transactions)).into_response())
        }
        StatementFormat::Ofx => {
            let mut ofx = String::new();
            ofx.push_str("OFXHEADER:100\n");
            ofx.push_str("DATA:OFXSGML\n");
            ofx.push_str("VERSION:102\n");
            ofx.push_str("SECURITY:NONE\n");
            ofx.push_str("ENCODING:USASCII\n");
            ofx.push_str("CHARSET:1252\n");
            ofx.push_str("COMPRESSION:NONE\n");
            ofx.push_str("OLDFILEUID:NONE\n");
            ofx.push_str("NEWFILEUID:NONE\n\n");
            ofx.push_str("<OFX>\n");
            ofx.push_str("<SIGNONMSGSRSV1>\n<SONRS>\n");
            
            let current_time = time::OffsetDateTime::now_utc();
            let time_format = time::format_description::parse("[year][month][day][hour][minute][second]").unwrap();
            let formatted_time = current_time.format(&time_format).unwrap();
            
            ofx.push_str(&format!("<DTSERVER>{}\n", formatted_time));
            ofx.push_str("<LANGUAGE>POR\n");
            ofx.push_str("</SONRS>\n</SIGNONMSGSRSV1>\n");
            ofx.push_str("<BANKMSGSRSV1>\n<STMTTRNRS>\n<STMTRS>\n");
            ofx.push_str("<CURDEF>BRL\n");
            ofx.push_str(&format!("<BANKACCTFROM>\n<BANKID>SYSTEMBANK</BANKID>\n<ACCTID>{}</ACCTID>\n<ACCTTYPE>CHECKING\n</BANKACCTFROM>\n", id));
            ofx.push_str("<BANKTRANLIST>\n");
            
            let from_str = from_date.format(&time_format).unwrap();
            let to_str = to_date.format(&time_format).unwrap();
            ofx.push_str(&format!("<DTSTART>{}\n<DTEND>{}\n", from_str, to_str));

            for tx in &transactions {
                let tx_time = tx.created_at.format(&time_format).unwrap();
                let tx_type = match tx.r#type {
                    crate::models::transaction::TransactionType::Credit => "CREDIT",
                    crate::models::transaction::TransactionType::Debit => "DEBIT",
                    crate::models::transaction::TransactionType::Transfer => "XFER",
                    crate::models::transaction::TransactionType::Fee => "FEE",
                };
                
                // Em OFX saídas (debitos) são geralmente valores negativos
                let mut amount = tx.amount;
                if matches!(tx.r#type, crate::models::transaction::TransactionType::Debit | crate::models::transaction::TransactionType::Fee) {
                    amount = -amount;
                }
                
                ofx.push_str("<STMTTRN>\n");
                ofx.push_str(&format!("<TRNTYPE>{}\n", tx_type));
                ofx.push_str(&format!("<DTPOSTED>{}\n", tx_time));
                ofx.push_str(&format!("<TRNAMT>{}\n", amount));
                ofx.push_str(&format!("<FITID>{}\n", tx.id));
                ofx.push_str(&format!("<MEMO>{}\n", tx.failure_reason.as_deref().unwrap_or("TRANSACTION")));
                ofx.push_str("</STMTTRN>\n");
            }
            
            ofx.push_str("</BANKTRANLIST>\n");
            ofx.push_str("</STMTRS>\n</STMTTRNRS>\n</BANKMSGSRSV1>\n");
            ofx.push_str("</OFX>");

            let response = (
                [(header::CONTENT_TYPE, "application/x-ofx")],
                ofx
            ).into_response();
            Ok(response)
        }
    }
}
