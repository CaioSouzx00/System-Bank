use crate::AppState;
use axum::{
    extract::{State, Json},
    routing::post,
    Router,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;

#[derive(Deserialize)]
pub struct JobCallbackPayload {
    pub job_type: String,
    pub status: String,
    pub process_date: String,
    pub records_processed: i32,
    pub error_message: Option<String>,
}

#[derive(Serialize)]
pub struct CallbackResponse {
    pub success: bool,
}

pub async fn job_callback(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<JobCallbackPayload>,
) -> Result<Json<CallbackResponse>, axum::http::StatusCode> {
    let job_type = payload.job_type.replace("-", "_");
    
    let result = sqlx::query!(
        r#"
        UPDATE batch_jobs
        SET status = $1,
            finished_at = NOW(),
            records_processed = $2,
            error_message = $3
        WHERE job_type = $4
          AND status = 'RUNNING'
          AND scheduled_for::date = $5::date
        "#,
        payload.status,
        payload.records_processed,
        payload.error_message,
        job_type,
        payload.process_date
    )
    .execute(&state.db)
    .await;

    match result {
        Ok(_) => Ok(Json(CallbackResponse { success: true })),
        Err(e) => {
            tracing::error!("Failed to update job status: {:?}", e);
            Err(axum::http::StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

pub fn router() -> Router<Arc<AppState>> {
    Router::new().route("/jobs/callback", post(job_callback))
}
