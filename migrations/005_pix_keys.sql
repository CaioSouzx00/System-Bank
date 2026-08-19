-- 005_pix_keys.sql
CREATE TABLE pix_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES accounts(id),
    key_type VARCHAR(20) NOT NULL, -- CPF, EMAIL, PHONE, RANDOM
    key_value VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
