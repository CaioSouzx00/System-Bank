      *> ============================================================
      *> DAILY-CLOSING.cbl — Fechamento de Caixa Diário
      *> Responsabilidade: consolidar saldos do dia, gerar sumário
      *> Invocado pelo worker Rust via batch.daily-closing queue
      *> ============================================================
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DAILY-CLOSING.
       AUTHOR.     SYSTEM-BANK.
       DATE-WRITTEN. 2024.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNTS-FILE ASSIGN TO DYNAMIC WS-ACCOUNTS-PATH
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT REPORT-FILE  ASSIGN TO DYNAMIC WS-REPORT-PATH
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD  ACCOUNTS-FILE.
       01  ACCOUNT-RECORD.
           05 AR-ACCOUNT-ID     PIC X(36).
           05 FILLER            PIC X(01).
           05 AR-BALANCE        PIC 9(15)V99.
           05 FILLER            PIC X(01).
           05 AR-STATUS         PIC X(10).

       FD  REPORT-FILE.
       01  REPORT-RECORD        PIC X(200).

       WORKING-STORAGE SECTION.
       01  WS-ACCOUNTS-PATH     PIC X(200).
       01  WS-REPORT-PATH       PIC X(200).
       01  WS-EOF               PIC X(01) VALUE 'N'.
       01  WS-TOTAL-ACCOUNTS    PIC 9(10) VALUE ZERO.
       01  WS-TOTAL-BALANCE     PIC 9(18)V99 VALUE ZERO.
       01  WS-ACTIVE-ACCOUNTS   PIC 9(10) VALUE ZERO.
       01  WS-PROCESS-DATE      PIC X(10).
       01  WS-RETURN-CODE       PIC 9(04) VALUE ZERO.

       PROCEDURE DIVISION.
       MAIN-PARA.
           ACCEPT WS-ACCOUNTS-PATH FROM ENVIRONMENT 'INPUT_FILE'
           ACCEPT WS-REPORT-PATH   FROM ENVIRONMENT 'OUTPUT_FILE'
           ACCEPT WS-PROCESS-DATE  FROM ENVIRONMENT 'PROCESS_DATE'

           OPEN INPUT  ACCOUNTS-FILE
           OPEN OUTPUT REPORT-FILE

           PERFORM UNTIL WS-EOF = 'Y'
               READ ACCOUNTS-FILE
                   AT END MOVE 'Y' TO WS-EOF
                   NOT AT END
                       PERFORM PROCESS-ACCOUNT
               END-READ
           END-PERFORM

           PERFORM WRITE-SUMMARY

           CLOSE ACCOUNTS-FILE
           CLOSE REPORT-FILE

           STOP RUN.

       PROCESS-ACCOUNT.
           ADD 1 TO WS-TOTAL-ACCOUNTS
           ADD AR-BALANCE TO WS-TOTAL-BALANCE
           IF AR-STATUS = 'ACTIVE'
               ADD 1 TO WS-ACTIVE-ACCOUNTS
           END-IF.

       WRITE-SUMMARY.
           MOVE FUNCTION CONCATENATE(
               'DATE='       WS-PROCESS-DATE ','
               'TOTAL_ACCTS=' FUNCTION TRIM(WS-TOTAL-ACCOUNTS LEADING) ','
               'ACTIVE_ACCTS=' FUNCTION TRIM(WS-ACTIVE-ACCOUNTS LEADING) ','
               'TOTAL_BALANCE=' FUNCTION TRIM(WS-TOTAL-BALANCE LEADING)
           ) TO REPORT-RECORD
           WRITE REPORT-RECORD.
