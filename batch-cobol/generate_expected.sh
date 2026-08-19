#!/bin/bash

# Compila
cd /app
make all

export COB_LS_FIXED=Y
export PROCESS_DATE="2024-08-19"

# 1. DAILY-CLOSING
export INPUT_FILE=tests/fixtures/DAILY-CLOSING-happy.txt
export OUTPUT_FILE=tests/expected/DAILY-CLOSING-happy.txt
./bin/DAILY-CLOSING

export INPUT_FILE=tests/fixtures/DAILY-CLOSING-empty.txt
export OUTPUT_FILE=tests/expected/DAILY-CLOSING-empty.txt
./bin/DAILY-CLOSING

export INPUT_FILE=tests/fixtures/DAILY-CLOSING-error.txt
export OUTPUT_FILE=tests/expected/DAILY-CLOSING-error.txt
./bin/DAILY-CLOSING

# 2. INTEREST-CALC
export INPUT_FILE=tests/fixtures/INTEREST-CALC-happy.txt
export OUTPUT_FILE=tests/expected/INTEREST-CALC-happy.txt
./bin/INTEREST-CALC

export INPUT_FILE=tests/fixtures/INTEREST-CALC-empty.txt
export OUTPUT_FILE=tests/expected/INTEREST-CALC-empty.txt
./bin/INTEREST-CALC

export INPUT_FILE=tests/fixtures/INTEREST-CALC-error.txt
export OUTPUT_FILE=tests/expected/INTEREST-CALC-error.txt
./bin/INTEREST-CALC

# 3. RECONCILIATION
export TRANS_FILE=tests/fixtures/RECONCILIATION-trans-happy.txt
export LEDGER_FILE=tests/fixtures/RECONCILIATION-ledger-happy.txt
export OUTPUT_FILE=tests/expected/RECONCILIATION-happy.txt
./bin/RECONCILIATION

export TRANS_FILE=tests/fixtures/RECONCILIATION-trans-empty.txt
export LEDGER_FILE=tests/fixtures/RECONCILIATION-ledger-empty.txt
export OUTPUT_FILE=tests/expected/RECONCILIATION-empty.txt
./bin/RECONCILIATION

export TRANS_FILE=tests/fixtures/RECONCILIATION-trans-error.txt
export LEDGER_FILE=tests/fixtures/RECONCILIATION-ledger-error.txt
export OUTPUT_FILE=tests/expected/RECONCILIATION-error.txt
./bin/RECONCILIATION

echo "Expected output files generated."
