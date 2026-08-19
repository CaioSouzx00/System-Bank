#!/bin/bash
# run-tests.sh
# Formato de saída: TAP (Test Anything Protocol)

echo "TAP version 14"
echo "1..9"

cd "$(dirname "$0")/.." || exit 1

export COB_LS_FIXED=Y
export PROCESS_DATE="2024-08-19"

mkdir -p tests/output

TEST_NUM=1

run_test() {
    local prog="$1"
    local scenario="$2"
    local env_setup="$3"
    local expected="tests/expected/${prog}-${scenario}.txt"
    local actual="tests/output/${prog}-${scenario}.txt"

    (
        eval "$env_setup"
        export OUTPUT_FILE="$actual"
        ./bin/$prog > /dev/null 2>&1
    )
    # Validate with diff
    if [ ! -f "$expected" ]; then
        echo "not ok $TEST_NUM - $prog $scenario (missing expected file $expected)"
    elif diff -u "$expected" "$actual" > "tests/output/${prog}-${scenario}.diff" 2>&1; then
        echo "ok $TEST_NUM - $prog $scenario"
    else
        echo "not ok $TEST_NUM - $prog $scenario (output mismatch)"
        sed 's/^/# /' "tests/output/${prog}-${scenario}.diff"
    fi
    TEST_NUM=$((TEST_NUM + 1))
}

# 1. DAILY-CLOSING
run_test "DAILY-CLOSING" "happy" "export INPUT_FILE=tests/fixtures/DAILY-CLOSING-happy.txt"
run_test "DAILY-CLOSING" "empty" "export INPUT_FILE=tests/fixtures/DAILY-CLOSING-empty.txt"
run_test "DAILY-CLOSING" "error" "export INPUT_FILE=tests/fixtures/DAILY-CLOSING-error.txt"

# 2. INTEREST-CALC
run_test "INTEREST-CALC" "happy" "export INPUT_FILE=tests/fixtures/INTEREST-CALC-happy.txt"
run_test "INTEREST-CALC" "empty" "export INPUT_FILE=tests/fixtures/INTEREST-CALC-empty.txt"
run_test "INTEREST-CALC" "error" "export INPUT_FILE=tests/fixtures/INTEREST-CALC-error.txt"

# 3. RECONCILIATION
run_test "RECONCILIATION" "happy" "export TRANS_FILE=tests/fixtures/RECONCILIATION-trans-happy.txt; export LEDGER_FILE=tests/fixtures/RECONCILIATION-ledger-happy.txt"
run_test "RECONCILIATION" "empty" "export TRANS_FILE=tests/fixtures/RECONCILIATION-trans-empty.txt; export LEDGER_FILE=tests/fixtures/RECONCILIATION-ledger-empty.txt"
run_test "RECONCILIATION" "error" "export TRANS_FILE=tests/fixtures/RECONCILIATION-trans-error.txt; export LEDGER_FILE=tests/fixtures/RECONCILIATION-ledger-error.txt"
