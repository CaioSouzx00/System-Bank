-- 001_initial_schema.sql
-- Schema inicial: accounts e transactions

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS accounts (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency         VARCHAR(4)    NOT NULL,
    account_number VARCHAR(10)   NOT NULL UNIQUE,
    owner_id       UUID          NOT NULL,
    balance        NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (balance >= 0),
    status         VARCHAR(20)   NOT NULL DEFAULT 'ACTIVE'
                       CHECK (status IN ('ACTIVE','BLOCKED','CLOSED')),
    created_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_accounts_owner_id ON accounts(owner_id);
CREATE INDEX idx_accounts_status   ON accounts(status);

CREATE TABLE IF NOT EXISTS transactions (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id               UUID          NOT NULL REFERENCES accounts(id),
    destination_account_id   UUID          REFERENCES accounts(id),
    type                     VARCHAR(20)   NOT NULL
                                 CHECK (type IN ('DEBIT','CREDIT','TRANSFER','FEE')),
    amount                   NUMERIC(18,2) NOT NULL CHECK (amount > 0),
    status                   VARCHAR(20)   NOT NULL DEFAULT 'PENDING'
                                 CHECK (status IN ('PENDING','PROCESSED','FAILED','REVERSED')),
    correlation_id           UUID          NOT NULL UNIQUE,
    failure_reason           TEXT,
    created_at               TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    processed_at             TIMESTAMPTZ
);

CREATE INDEX idx_transactions_account_id     ON transactions(account_id);
CREATE INDEX idx_transactions_correlation_id ON transactions(correlation_id);
CREATE INDEX idx_transactions_status         ON transactions(status);
