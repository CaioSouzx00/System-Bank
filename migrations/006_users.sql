-- 006_users.sql
-- Cria a tabela de usuários e o relacionamento com accounts

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cpf VARCHAR(255) NOT NULL UNIQUE, -- Armazenado criptografado via pgcrypto (aumentado para 255 pra suportar o dado criptografado)
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL, -- Argon2id
    role VARCHAR(20) NOT NULL DEFAULT 'CLIENT', -- CLIENT | OPERATOR | ADMIN
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
-- Índice para o CPF, embora com pgcrypto (e salt) não seja util para busca de igualdade simples.
CREATE INDEX idx_users_cpf ON users(cpf);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Adiciona a foreign key em accounts referenciando users.
-- Nota: se já existirem registros em accounts sem um usuario correspondente, esta migration falhará.
ALTER TABLE accounts
ADD CONSTRAINT fk_accounts_owner_id
FOREIGN KEY (owner_id) REFERENCES users(id);
