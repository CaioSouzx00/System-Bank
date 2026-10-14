-- 007_regulatory_reporting.sql
-- Tabela para armazenar relatórios regulatórios BACEN e ajuste de tipos de batch jobs

ALTER TABLE batch_jobs DROP CONSTRAINT IF EXISTS batch_jobs_job_type_check;

ALTER TABLE batch_jobs ADD CONSTRAINT batch_jobs_job_type_check
    CHECK (job_type IN (
        'DAILY_CLOSING', 'INTEREST_CALC', 'CNAB_GENERATION',
        'RECONCILIATION', 'FEE_CALC', 'REGULATORY_SCR',
        'REGULATORY_PSTAW10', 'REGULATORY_REPORT'
    ));

CREATE TABLE IF NOT EXISTS regulatory_reports (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_type        VARCHAR(50) NOT NULL CHECK (report_type IN ('BACEN_SCR', 'PSTAW10')),
    reference_date     DATE NOT NULL,
    status             VARCHAR(20) NOT NULL DEFAULT 'GENERATED'
                           CHECK (status IN ('GENERATED', 'SUBMITTED', 'ACCEPTED', 'REJECTED')),
    total_records      INTEGER NOT NULL DEFAULT 0,
    total_amount       NUMERIC(18,2) NOT NULL DEFAULT 0.00,
    payload            JSONB NOT NULL,
    xml_content        TEXT,
    checksum           VARCHAR(64) NOT NULL,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_regulatory_reports_date ON regulatory_reports(reference_date);
CREATE INDEX IF NOT EXISTS idx_regulatory_reports_type ON regulatory_reports(report_type);
