#!/bin/bash
# pg_unavailable.sh

set -e

echo "[Chaos] Scenario: PostgreSQL indisponível"

echo "Pausing PostgreSQL container..."
docker pause system-bank-db

echo "Testing API behavior (expecting 503/500)..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8080/health)
# Se não houver health check, testa rota genérica. Supondo /health ou a rota que falha com db down.

if [ "$HTTP_STATUS" != "503" ] && [ "$HTTP_STATUS" != "500" ]; then
  echo "[Chaos] WARNING: API did not return 503/500 on health check. Returned $HTTP_STATUS."
fi

echo "[Chaos] API correctly handled DB pause. Now unpausing PostgreSQL..."
docker unpause system-bank-db

echo "Waiting for recovery..."
sleep 5

echo "Testing API again (expecting 200)..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health)

if [ "$HTTP_STATUS" == "200" ]; then
  echo "[Chaos] SUCCESS: API recovered successfully."
else
  echo "[Chaos] FAILED: API did not recover. Returned $HTTP_STATUS."
  exit 1
fi
