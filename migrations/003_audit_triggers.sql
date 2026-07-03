-- 003_audit_logs.sql
-- Auditoria imutável (append-only)

CREATE TABLE IF NOT EXISTS audit_logs (
    id          BIGSERIAL   PRIMARY KEY,
    actor       UUID        NOT NULL,
    action      VARCHAR(50) NOT NULL,
    entity      VARCHAR(50) NOT NULL,
    entity_id   UUID        NOT NULL,
    payload     JSONB,
    ip_address  INET,
    timestamp   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_entity    ON audit_logs(entity, entity_id);
CREATE INDEX idx_audit_actor     ON audit_logs(actor);
CREATE INDEX idx_audit_timestamp ON audit_logs(timestamp DESC);

-- Trigger de imutabilidade: impede UPDATE e DELETE
CREATE OR REPLACE FUNCTION audit_logs_immutable()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION
        'audit_logs é append-only. Operação % não é permitida.', TG_OP;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_audit_immutability
BEFORE UPDATE OR DELETE ON audit_logs
FOR EACH ROW EXECUTE FUNCTION audit_logs_immutable();

-- Trigger automático: registra toda mudança de status em transactions
CREATE OR REPLACE FUNCTION log_transaction_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO audit_logs (actor, action, entity, entity_id, payload)
        VALUES (
            '00000000-0000-0000-0000-000000000000'::UUID, -- system actor
            'TRANSACTION_STATUS_CHANGE',
            'transactions',
            NEW.id,
            jsonb_build_object(
                'from_status', OLD.status,
                'to_status',   NEW.status,
                'correlation_id', NEW.correlation_id
            )
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit_transaction_status
AFTER UPDATE ON transactions
FOR EACH ROW EXECUTE FUNCTION log_transaction_change();
