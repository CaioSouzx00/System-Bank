#!/bin/bash
# rabbitmq_restart.sh

set -e

echo "[Chaos] Scenario: RabbitMQ reinicia"

echo "Restarting RabbitMQ container..."
docker restart system-bank-mq

echo "Waiting for RabbitMQ to come back..."
sleep 15

echo "Testing API behavior post-recovery..."
# Supondo que a rota de health check verifica o RabbitMQ também, ou envia uma mensagem.
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health)

if [ "$HTTP_STATUS" == "200" ]; then
  echo "[Chaos] SUCCESS: System is accepting messages/healthy after RabbitMQ restart."
else
  echo "[Chaos] FAILED: System failed to recover after RabbitMQ restart. Returned $HTTP_STATUS"
  exit 1
fi
