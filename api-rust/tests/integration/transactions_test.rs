use crate::common;
use axum::http::StatusCode;
use serde_json::json;
use uuid::Uuid;

#[tokio::test]
async fn test_create_transaction_success() {
    let app = common::setup().await;
    let user_id = Uuid::new_v4();
    let token = common::generate_token(user_id);

    // Create an account for the user first
    let create_account_res = app.server.post("/accounts")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&json!({
            "agency": "0001"
        }))
        .await;
    
    create_account_res.assert_status(StatusCode::CREATED);
    let account: serde_json::Value = create_account_res.json();
    let account_id = account["id"].as_str().unwrap();

    let correlation_id = Uuid::new_v4();
    let res = app.server.post("/transactions")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&json!({
            "correlation_id": correlation_id,
            "account_id": account_id,
            "type": "CREDIT",
            "amount": "100.00"
        }))
        .await;
    
    res.assert_status(StatusCode::ACCEPTED);
}

#[tokio::test]
async fn test_create_transaction_idempotency() {
    let app = common::setup().await;
    let user_id = Uuid::new_v4();
    let token = common::generate_token(user_id);

    let create_account_res = app.server.post("/accounts")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&json!({"agency": "0001"}))
        .await;
    let account: serde_json::Value = create_account_res.json();
    let account_id = account["id"].as_str().unwrap();

    let correlation_id = Uuid::new_v4();
    let payload = json!({
        "correlation_id": correlation_id,
        "account_id": account_id,
        "type": "CREDIT",
        "amount": "100.00"
    });

    // First request
    app.server.post("/transactions")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&payload)
        .await
        .assert_status(StatusCode::ACCEPTED);

    // Second request with same correlation_id
    app.server.post("/transactions")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&payload)
        .await
        .assert_status(StatusCode::ACCEPTED);
}

#[tokio::test]
async fn test_create_transaction_unauthorized() {
    let app = common::setup().await;
    
    let res = app.server.post("/transactions")
        .json(&json!({
            "correlation_id": Uuid::new_v4(),
            "account_id": Uuid::new_v4(),
            "type": "CREDIT",
            "amount": "100.00"
        }))
        .await;
    
    res.assert_status(StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn test_create_transaction_negative_amount() {
    let app = common::setup().await;
    let user_id = Uuid::new_v4();
    let token = common::generate_token(user_id);

    let create_account_res = app.server.post("/accounts")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&json!({"agency": "0001"}))
        .await;
    let account: serde_json::Value = create_account_res.json();
    let account_id = account["id"].as_str().unwrap();

    let res = app.server.post("/transactions")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&json!({
            "correlation_id": Uuid::new_v4(),
            "account_id": account_id,
            "type": "CREDIT",
            "amount": "-100.00"
        }))
        .await;
    
    res.assert_status(StatusCode::UNPROCESSABLE_ENTITY);
}
