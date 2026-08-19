import os

def pad(s, length):
    return str(s).ljust(length)

def rpad(s, length, fill='0'):
    return str(s).rjust(length, fill)

def write_file(path, lines):
    with open(path, 'w', newline='\n') as f:
        for line in lines:
            f.write(line + '\n')

os.makedirs('batch-cobol/tests/fixtures', exist_ok=True)
os.makedirs('batch-cobol/tests/expected', exist_ok=True)

# --- DAILY-CLOSING ---
write_file('batch-cobol/tests/fixtures/DAILY-CLOSING-happy.txt', [
    f"{pad('1111', 36)} {rpad('100050', 17)} {pad('ACTIVE', 10)}",
    f"{pad('2222', 36)} {rpad('200000', 17)} {pad('INACTIVE', 10)}",
    f"{pad('3333', 36)} {rpad('300050', 17)} {pad('ACTIVE', 10)}"
])
write_file('batch-cobol/tests/fixtures/DAILY-CLOSING-empty.txt', [])
write_file('batch-cobol/tests/fixtures/DAILY-CLOSING-error.txt', [
    f"{pad('ERR1', 36)} {rpad('0', 17)} {pad('ERROR', 10)}"
])

# --- INTEREST-CALC ---
# DA-ACCOUNT-ID(36) + ' ' + DA-BALANCE S9(15)V99(17) + ' ' + DA-RATE 9(03)V9(06)(9) + ' ' + DA-DAYS 9(04)(4)
write_file('batch-cobol/tests/fixtures/INTEREST-CALC-happy.txt', [
    f"{pad('1111', 36)} {rpad('100050', 17)} {rpad('010000000', 9)} {rpad('30', 4)}",
])
write_file('batch-cobol/tests/fixtures/INTEREST-CALC-empty.txt', [])
write_file('batch-cobol/tests/fixtures/INTEREST-CALC-error.txt', [
    f"{pad('ERR1', 36)} {rpad('0', 17)} {rpad('0', 9)} {rpad('0', 4)}"
])

# --- RECONCILIATION ---
# TRANS: TR-ID(36) + ' ' + TR-ACCOUNT-ID(36) + ' ' + TR-TYPE(10) + ' ' + TR-AMOUNT 9(16)V99(18)
# LEDGER: LE-ID(36) + ' ' + LE-TRANS-ID(36) + ' ' + LE-ACCOUNT-ID(36) + ' ' + LE-TYPE(10) + ' ' + LE-AMOUNT(18)

# happy path (recon equals)
# Trans ID: T1
write_file('batch-cobol/tests/fixtures/RECONCILIATION-trans-happy.txt', [
    f"{pad('T1', 36)} {pad('1111', 36)} {pad('DEBIT', 10)} {rpad('100050', 18)}"
])
# Ledger has 1 DEBIT and 1 CREDIT for T1, equal amounts
write_file('batch-cobol/tests/fixtures/RECONCILIATION-ledger-happy.txt', [
    f"{pad('L1', 36)} {pad('T1', 36)} {pad('1111', 36)} {pad('DEBIT', 10)} {rpad('100050', 18)}",
    f"{pad('L2', 36)} {pad('T1', 36)} {pad('1111', 36)} {pad('CREDIT', 10)} {rpad('100050', 18)}"
])

# empty
write_file('batch-cobol/tests/fixtures/RECONCILIATION-trans-empty.txt', [])
write_file('batch-cobol/tests/fixtures/RECONCILIATION-ledger-empty.txt', [])

# error path (divergence)
# Trans ID: T2
write_file('batch-cobol/tests/fixtures/RECONCILIATION-trans-error.txt', [
    f"{pad('T2', 36)} {pad('2222', 36)} {pad('DEBIT', 10)} {rpad('200000', 18)}"
])
# Ledger only has DEBIT, no CREDIT, or amounts don't match
write_file('batch-cobol/tests/fixtures/RECONCILIATION-ledger-error.txt', [
    f"{pad('L3', 36)} {pad('T2', 36)} {pad('2222', 36)} {pad('DEBIT', 10)} {rpad('200000', 18)}",
    f"{pad('L4', 36)} {pad('T2', 36)} {pad('2222', 36)} {pad('CREDIT', 10)} {rpad('150000', 18)}"
])

print("Fixtures created.")
