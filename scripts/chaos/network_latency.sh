#!/bin/bash
# network_latency.sh

set -e

echo "[Chaos] Scenario: Latência de rede simulada"

echo "Injecting network latency (500ms) on API container..."
# Using docker exec to add latency. The image might not have tc (iproute2) by default.
docker exec -u root system-bank-api sh -c "apk add --no-cache iproute2 && tc qdisc add dev eth0 root netem delay 500ms" || echo "TC might already be configured or unsupported."

echo "Testing API behavior..."
START_TIME=$(date +%s%3N)
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health)
END_TIME=$(date +%s%3N)
DURATION=$((END_TIME - START_TIME))

echo "Request took ${DURATION}ms. Status: $HTTP_STATUS"

if [ "$DURATION" -lt 500 ]; then
  echo "[Chaos] WARNING: Latency injection might not have worked. Duration was ${DURATION}ms"
fi

echo "Removing network latency..."
docker exec -u root system-bank-api sh -c "tc qdisc del dev eth0 root netem" || true

echo "[Chaos] SUCCESS: Network latency scenario completed."
