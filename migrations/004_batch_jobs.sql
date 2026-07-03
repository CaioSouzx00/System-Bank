-- 004_batch_jobs.sql
-- Controle de jobs COBOL

CREATE TABLE IF NOT EXISTS batch_jobs (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_type           VARCHAR(50)  NOT NULL
                           CHECK (job_type IN (
                               'DAILY_CLOSING','INTEREST_CALC',
                               'CNAB_GENERATION','RECONCILIATION','FEE_CALC'
                           )),
    status             VARCHAR(20)  NOT NULL DEFAULT 'SCHEDULED'
                           CHECK (status IN ('SCHEDULED','RUNNING','COMPLETED','FAILED')),
    scheduled_for      TIMESTAMPTZ  NOT NULL,
    started_at         TIMESTAMPTZ,
    finished_at        TIMESTAMPTZ,
    records_processed  INTEGER DEFAULT 0,
    error_message      TEXT,
    triggered_by       VARCHAR(20)  NOT NULL DEFAULT 'SCHEDULER'
                           CHECK (triggered_by IN ('SCHEDULER','MANUAL','EVENT'))
);

CREATE INDEX idx_batch_jobs_status ON batch_jobs(status);
CREATE INDEX idx_batch_jobs_type   ON batch_jobs(job_type);
