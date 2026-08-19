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

# Cria arquivos temporários para os certificados se eles existirem
if [[ -n "${CA_CERT_B64:-}" && -n "${CLIENT_CERT_B64:-}" && -n "${CLIENT_KEY_B64:-}" ]]; then
  echo "$CA_CERT_B64" | base64 -d > /tmp/ca.crt
  echo "$CLIENT_CERT_B64" | base64 -d > /tmp/client.crt
  echo "$CLIENT_KEY_B64" | base64 -d > /tmp/client.key

  # Registra na API usando mTLS
  API_URL="https://api:8080/internal/jobs/callback"
  echo "[$(date -Iseconds)] Enviando callback via mTLS para ${API_URL}"
  curl -s -X POST "${API_URL}" \
    --cacert /tmp/ca.crt \
    --cert /tmp/client.crt \
    --key /tmp/client.key \
    -H "Content-Type: application/json" \
    -d "{ \"job_type\": \"${JOB_TYPE}\", \"status\": \"${STATUS}\", \"process_date\": \"${PROCESS_DATE}\", \"records_processed\": ${RECORDS} }"
else
  # Registra no banco via psql (fallback/modo antigo se não houver mTLS)
  echo "[$(date -Iseconds)] Enviando callback via psql"
  psql "${DATABASE_URL}" <<SQL
    UPDATE batch_jobs
    SET status = '${STATUS}',
        finished_at = NOW(),
        records_processed = ${RECORDS}
    WHERE job_type = '${JOB_TYPE//-/_}'
      AND status = 'RUNNING'
      AND scheduled_for::date = '${PROCESS_DATE}';
SQL
fi

[[ "$STATUS" == "FAILED" ]] && exit 1
exit 0
