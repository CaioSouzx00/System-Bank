-- 002_ledger_entries.sql
-- Dupla entrada contábil

CREATE TABLE IF NOT EXISTS ledger_entries (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id  UUID          NOT NULL REFERENCES transactions(id),
    account_id      UUID          NOT NULL REFERENCES accounts(id),
    entry_type      VARCHAR(10)   NOT NULL CHECK (entry_type IN ('DEBIT','CREDIT')),
    amount          NUMERIC(18,2) NOT NULL CHECK (amount > 0),
    balance_after   NUMERIC(18,2) NOT NULL,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ledger_transaction_id ON ledger_entries(transaction_id);
CREATE INDEX idx_ledger_account_id     ON ledger_entries(account_id);
