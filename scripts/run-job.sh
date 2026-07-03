#!/usr/bin/env bash
# run-job.sh — Executa um programa COBOL e registra o resultado no PostgreSQL
# Uso: ./run-job.sh <JOB_TYPE> [DATA]
# Exemplo: ./run-job.sh DAILY-CLOSING 2024-01-15

set -euo pipefail

JOB_TYPE="${1:-}"
PROCESS_DATE="${2:-$(date +%Y-%m-%d)}"

if [[ -z "$JOB_TYPE" ]]; then
  echo "Uso: $0 <JOB_TYPE> [DATA]" >&2
  echo "Tipos válidos: DAILY-CLOSING, INTEREST-CALC, CNAB240-GEN, RECONCILIATION, FEE-CALC" >&2
  exit 1
fi

BIN="./bin/${JOB_TYPE}"
INPUT_FILE="./io/input/${JOB_TYPE}-${PROCESS_DATE}.dat"
OUTPUT_FILE="./io/output/${JOB_TYPE}-${PROCESS_DATE}.out"

if [[ ! -x "$BIN" ]]; then
  echo "Binário não encontrado ou não executável: $BIN" >&2
  exit 1
fi

echo "[$(date -Iseconds)] Iniciando job ${JOB_TYPE} para ${PROCESS_DATE}"

export INPUT_FILE OUTPUT_FILE PROCESS_DATE

START_TIME=$(date -Iseconds)

if INPUT_FILE="$INPUT_FILE" OUTPUT_FILE="$OUTPUT_FILE" PROCESS_DATE="$PROCESS_DATE" "$BIN"; then
  STATUS="COMPLETED"
  RECORDS=$(wc -l < "$OUTPUT_FILE" 2>/dev/null || echo 0)
  echo "[$(date -Iseconds)] Job ${JOB_TYPE} concluído — ${RECORDS} registros"
else
  STATUS="FAILED"
  RECORDS=0
  echo "[$(date -Iseconds)] Job ${JOB_TYPE} falhou" >&2
fi

# Registra no banco via psql
psql "${DATABASE_URL}" <<SQL
  UPDATE batch_jobs
  SET status = '${STATUS}',
      finished_at = NOW(),
      records_processed = ${RECORDS}
  WHERE job_type = '${JOB_TYPE//-/_}'
    AND status = 'RUNNING'
    AND scheduled_for::date = '${PROCESS_DATE}';
SQL

[[ "$STATUS" == "FAILED" ]] && exit 1
exit 0
