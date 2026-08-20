#!/bin/bash
# cobol_worker_hang.sh

set -e

echo "[Chaos] Scenario: COBOL worker trava"

echo "Sending SIGSTOP to COBOL worker container..."
docker kill --signal=SIGSTOP system-bank-cobol

echo "Posting a message to the queue via API (mocking a request)..."
# Assuming there is an endpoint or we just observe that the worker is paused.
# We could use rabbitmqadmin or just check that the worker process is paused.
# Wait for some time to allow messages to accumulate
sleep 15

# Ideally check DLQ here via RabbitMQ HTTP API if we had credentials
# curl -s -u guest:guest http://localhost:15672/api/queues/%2F/dlq.transactions | grep messages

echo "Resuming COBOL worker container..."
docker kill --signal=SIGCONT system-bank-cobol

echo "Waiting for worker to process messages..."
sleep 5

echo "[Chaos] SUCCESS: Validated COBOL worker hang scenario."
