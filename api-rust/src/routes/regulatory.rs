use axum::{
    extract::{Query, State},
    http::{header, StatusCode},
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use std::sync::Arc;

use crate::{
    errors::{AppError, AppResult},
    models::regulatory::{RegulatoryQuery, SimulateRegulatoryRequest},
    services::regulatory_service,
    AppState,
};

pub fn router() -> Router<Arc<AppState>> {
    Router::new()
        .route("/scr", get(get_bacen_scr))
        .route("/pstaw10", get(get_bacen_pstaw10))
        .route("/reports", get(list_regulatory_reports))
        .route("/simulate", post(simulate_regulatory))
}

async fn get_bacen_scr(
    State(state): State<Arc<AppState>>,
    Query(query): Query<RegulatoryQuery>,
) -> AppResult<impl IntoResponse> {
    let date_str = query.date.unwrap_or_else(|| {
        time::OffsetDateTime::now_utc().date().to_string()
    });

    let (report, xml, _checksum) = regulatory_service::generate_scr(&state.db, &date_str).await?;

    let format = query.format.unwrap_or_else(|| "json".to_string()).to_lowercase();
    if format == "xml" {
        let response = (
            [(header::CONTENT_TYPE, "application/xml; charset=utf-8")],
            xml,
        )
            .into_response();
        Ok(response)
    } else {
        Ok((StatusCode::OK, Json(report)).into_response())
    }
}

async fn get_bacen_pstaw10(
    State(state): State<Arc<AppState>>,
    Query(query): Query<RegulatoryQuery>,
) -> AppResult<impl IntoResponse> {
    let date_str = query.date.unwrap_or_else(|| {
        time::OffsetDateTime::now_utc().date().to_string()
    });

    let (report, xml, _checksum) = regulatory_service::generate_pstaw10(&state.db, &date_str).await?;

    let format = query.format.unwrap_or_else(|| "json".to_string()).to_lowercase();
    if format == "xml" {
        let response = (
            [(header::CONTENT_TYPE, "application/xml; charset=utf-8")],
            xml,
        )
            .into_response();
        Ok(response)
    } else {
        Ok((StatusCode::OK, Json(report)).into_response())
    }
}

async fn list_regulatory_reports(
    State(state): State<Arc<AppState>>,
) -> AppResult<impl IntoResponse> {
    let reports = regulatory_service::list_reports(&state.db).await?;
    Ok(Json(reports))
}

async fn simulate_regulatory(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<SimulateRegulatoryRequest>,
) -> AppResult<impl IntoResponse> {
    match payload.report_type.to_uppercase().as_str() {
        "BACEN_SCR" | "SCR" | "3040" => {
            let (report, xml, checksum) = regulatory_service::generate_scr(&state.db, &payload.reference_date).await?;
            Ok(Json(serde_json::json!({
                "status": "SUCCESS",
                "report_type": "BACEN_SCR",
                "checksum": checksum,
                "data": report,
                "xml_preview": xml
            })))
        }
        "PSTAW10" | "BACEN_PSTAW10" => {
            let (report, xml, checksum) = regulatory_service::generate_pstaw10(&state.db, &payload.reference_date).await?;
            Ok(Json(serde_json::json!({
                "status": "SUCCESS",
                "report_type": "PSTAW10",
                "checksum": checksum,
                "data": report,
                "xml_preview": xml
            })))
        }
        _ => Err(AppError::BadRequest("Tipo de relatório inválido. Use BACEN_SCR ou PSTAW10".into()))
    }
}
