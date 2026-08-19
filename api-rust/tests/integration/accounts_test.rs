use crate::common;
use axum::http::StatusCode;
use serde_json::json;
use uuid::Uuid;

#[tokio::test]
async fn test_create_account_success() {
    let app = common::setup().await;
    let user_id = Uuid::new_v4();
    let token = common::generate_token(user_id);

    let res = app.server.post("/accounts")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&json!({"agency": "0001"}))
        .await;
    
    res.assert_status(StatusCode::CREATED);
}

#[tokio::test]
async fn test_create_account_invalid_agency() {
    let app = common::setup().await;
    let user_id = Uuid::new_v4();
    let token = common::generate_token(user_id);

    let res = app.server.post("/accounts")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&json!({"agency": "invalid"}))
        .await;
    
    res.assert_status(StatusCode::BAD_REQUEST);
}

#[tokio::test]
async fn test_get_own_account() {
    let app = common::setup().await;
    let user_id = Uuid::new_v4();
    let token = common::generate_token(user_id);

    let create_res = app.server.post("/accounts")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&json!({"agency": "0001"}))
        .await;
    let account: serde_json::Value = create_res.json();
    let account_id = account["id"].as_str().unwrap();

    let get_res = app.server.get(&format!("/accounts/{}", account_id))
        .add_header("Authorization", format!("Bearer {}", token))
        .await;
    
    get_res.assert_status(StatusCode::OK);
}

#[tokio::test]
async fn test_get_other_user_account() {
    let app = common::setup().await;
    
    // User A
    let user_a_id = Uuid::new_v4();
    let token_a = common::generate_token(user_a_id);
    let create_res = app.server.post("/accounts")
        .add_header("Authorization", format!("Bearer {}", token_a))
        .json(&json!({"agency": "0001"}))
        .await;
    let account: serde_json::Value = create_res.json();
    let account_id = account["id"].as_str().unwrap();

    // User B
    let user_b_id = Uuid::new_v4();
    let token_b = common::generate_token(user_b_id);

    // User B tries to access User A's account
    let get_res = app.server.get(&format!("/accounts/{}", account_id))
        .add_header("Authorization", format!("Bearer {}", token_b))
        .await;
    
    get_res.assert_status(StatusCode::NOT_FOUND);
}
