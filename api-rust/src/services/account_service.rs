use sqlx::PgPool;
use uuid::Uuid;

use crate::{
    errors::{AppError, AppResult},
    models::account::{Account, CreateAccountRequest},
};

pub async fn find_by_owner(db: &PgPool, owner_id: Uuid) -> AppResult<Vec<Account>> {
    let accounts = sqlx::query_as!(
        Account,
        r#"SELECT id, agency, account_number, owner_id, balance, status as "status: _", created_at
           FROM accounts
           WHERE owner_id = $1 AND status != 'CLOSED'
           ORDER BY created_at DESC"#,
        owner_id
    )
    .fetch_all(db)
    .await?;

    Ok(accounts)
}

pub async fn find_by_id_and_owner(db: &PgPool, id: Uuid, owner_id: Uuid) -> AppResult<Account> {
    sqlx::query_as!(
        Account,
        r#"SELECT id, agency, account_number, owner_id, balance, status as "status: _", created_at
           FROM accounts
           WHERE id = $1 AND owner_id = $2"#,
        id,
        owner_id
    )
    .fetch_optional(db)
    .await?
    .ok_or_else(|| AppError::NotFound("Conta não encontrada".into()))
}

pub async fn create(db: &PgPool, req: CreateAccountRequest, owner_id: Uuid) -> AppResult<Account> {
    // Gera número de conta sequencial dentro da agência
    let account_number = generate_account_number(db, &req.agency).await?;

    let account = sqlx::query_as!(
        Account,
        r#"INSERT INTO accounts (id, agency, account_number, owner_id, balance, status)
           VALUES (gen_random_uuid(), $1, $2, $3, 0, 'ACTIVE')
           RETURNING id, agency, account_number, owner_id, balance, status as "status: _", created_at"#,
        req.agency,
        account_number,
        owner_id
    )
    .fetch_one(db)
    .await?;

    Ok(account)
}

async fn generate_account_number(db: &PgPool, agency: &str) -> AppResult<String> {
    let count: i64 = sqlx::query_scalar!(
        "SELECT COUNT(*) FROM accounts WHERE agency = $1",
        agency
    )
    .fetch_one(db)
    .await?
    .unwrap_or(0);

    let number = count + 1;
    // Formato: NNNNNNN-D (7 dígitos + dígito verificador simples)
    let base = format!("{:07}", number);
    let digit = base.chars().map(|c| c.to_digit(10).unwrap_or(0)).sum::<u32>() % 10;
    Ok(format!("{}-{}", base, digit))
}
