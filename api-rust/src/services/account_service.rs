use rust_decimal::Decimal;
use rust_decimal::prelude::ToPrimitive;
use rust_decimal_macros::dec;
use sqlx::PgPool;
use uuid::Uuid;

use crate::{
    errors::{AppError, AppResult},
    models::account::{Account, CreateAccountRequest},
};

#[derive(Debug, serde::Serialize, serde::Deserialize)]
pub struct InterestSimulationResult {
    pub account_id: Uuid,
    pub current_balance: Decimal,
    pub annual_rate: Decimal,
    pub days: i32,
    pub monthly_rate: Decimal,
    pub daily_rate: Decimal,
    pub compound_factor: Decimal,
    pub interest_amount: Decimal,
    pub projected_balance: Decimal,
}

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
    .await?;

    let number = count + 1;
    // Formato: NNNNNNN-D (7 dígitos + dígito verificador simples)
    let base = format!("{:07}", number);
    let digit = base.chars().map(|c| c.to_digit(10).unwrap_or(0)).sum::<u32>() % 10;
    Ok(format!("{}-{}", base, digit))
}

pub async fn block(db: &PgPool, id: Uuid) -> AppResult<Account> {
    sqlx::query_as!(
        Account,
        r#"UPDATE accounts
           SET status = 'BLOCKED'
           WHERE id = $1
           RETURNING id, agency, account_number, owner_id, balance, status as "status: _", created_at"#,
        id
    )
    .fetch_optional(db)
    .await?
    .ok_or_else(|| AppError::NotFound("Conta não encontrada".into()))
}

/// Alias público de `find_by_owner` — mantém compatibilidade com chamadas de outros módulos
pub async fn list(db: &PgPool, owner_id: Uuid) -> AppResult<Vec<Account>> {
    find_by_owner(db, owner_id).await
}

pub async fn simulate_interest(
    db: &PgPool,
    account_id: Uuid,
    owner_id: Uuid,
    annual_rate_opt: Option<Decimal>,
    days_opt: Option<i32>,
) -> AppResult<InterestSimulationResult> {
    let account = find_by_id_and_owner(db, account_id, owner_id).await?;
    let annual_rate = annual_rate_opt.unwrap_or(dec!(12.0)); // 12% a.a. default
    let days = days_opt.unwrap_or(30);

    let rate_f64 = annual_rate.to_f64().unwrap_or(12.0) / 100.0;
    let monthly_rate_f64 = rate_f64 / 12.0;
    let daily_rate_f64 = (1.0 + monthly_rate_f64).powf(1.0 / 30.0) - 1.0;
    let compound_factor_f64 = (1.0 + daily_rate_f64).powi(days);

    let balance_f64 = account.balance.to_f64().unwrap_or(0.0);
    let interest_f64 = balance_f64 * (compound_factor_f64 - 1.0);
    let projected_f64 = balance_f64 + interest_f64;

    let monthly_rate = Decimal::from_f64_retain(monthly_rate_f64).unwrap_or(Decimal::ZERO).round_dp(6);
    let daily_rate = Decimal::from_f64_retain(daily_rate_f64).unwrap_or(Decimal::ZERO).round_dp(8);
    let compound_factor = Decimal::from_f64_retain(compound_factor_f64).unwrap_or(Decimal::ONE).round_dp(6);
    let interest_amount = Decimal::from_f64_retain(interest_f64).unwrap_or(Decimal::ZERO).round_dp(2);
    let projected_balance = Decimal::from_f64_retain(projected_f64).unwrap_or(account.balance).round_dp(2);

    Ok(InterestSimulationResult {
        account_id,
        current_balance: account.balance,
        annual_rate,
        days,
        monthly_rate,
        daily_rate,
        compound_factor,
        interest_amount,
        projected_balance,
    })
}
