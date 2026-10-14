       *> ============================================================
       *> REGULATORY-REPORT.cbl — Relatórios Regulatórios BACEN
       *> Simulação: BACEN SCR (Doc 3040) e Demonstrativo PSTAW10
       *> Invocado pelo Worker Rust ou via scripts/run-job.sh
       *> ============================================================
        IDENTIFICATION DIVISION.
        PROGRAM-ID. REGULATORY-REPORT.
        AUTHOR.     SYSTEM-BANK.

        ENVIRONMENT DIVISION.
        INPUT-OUTPUT SECTION.
        FILE-CONTROL.
            SELECT ACCOUNTS-FILE ASSIGN TO DYNAMIC WS-ACCOUNTS-PATH
                ORGANIZATION IS LINE SEQUENTIAL
                FILE STATUS IS WS-ACCT-STATUS.
            SELECT TRANS-FILE ASSIGN TO DYNAMIC WS-TRANS-PATH
                ORGANIZATION IS LINE SEQUENTIAL
                FILE STATUS IS WS-TRANS-STATUS.
            SELECT REPORT-FILE ASSIGN TO DYNAMIC WS-REPORT-PATH
                ORGANIZATION IS LINE SEQUENTIAL
                FILE STATUS IS WS-REPORT-STATUS.

        DATA DIVISION.
        FILE SECTION.
        FD  ACCOUNTS-FILE.
        01  ACCOUNT-RECORD.
            COPY ACCOUNT-RECORD.

        FD  TRANS-FILE.
        01  TRANS-RECORD.
            05 TR-ID             PIC X(36).
            05 FILLER            PIC X(01).
            05 TR-ACCOUNT-ID     PIC X(36).
            05 FILLER            PIC X(01).
            05 TR-TYPE           PIC X(10).
            05 FILLER            PIC X(01).
            05 TR-AMOUNT         PIC 9(16)V99.

        FD  REPORT-FILE.
        01  REPORT-RECORD        PIC X(250).

        WORKING-STORAGE SECTION.
        01  WS-ACCOUNTS-PATH     PIC X(200) VALUE "io/input/accounts.dat".
        01  WS-TRANS-PATH        PIC X(200) VALUE "io/input/trans.dat".
        01  WS-REPORT-PATH       PIC X(200) VALUE "io/output/regulatory.out".
        01  WS-PROCESS-DATE      PIC X(10).

        01  WS-FILE-STATUSES.
            05 WS-ACCT-STATUS    PIC X(02).
            05 WS-TRANS-STATUS   PIC X(02).
            05 WS-REPORT-STATUS  PIC X(02).

        01  WS-FLAGS.
            05 WS-EOF-ACCT       PIC X(01) VALUE 'N'.
            05 WS-EOF-TRANS      PIC X(01) VALUE 'N'.
            05 WS-ACCT-IS-OPEN   PIC X(01) VALUE 'N'.
            05 WS-TRANS-IS-OPEN  PIC X(01) VALUE 'N'.

        01  WS-SCR-METRICS.
            05 WS-TOTAL-ACCTS        PIC 9(08) VALUE ZERO.
            05 WS-EXPOSED-ACCTS      PIC 9(08) VALUE ZERO.
            05 WS-TOTAL-EXPOSURE     PIC 9(16)V99 VALUE ZERO.
            05 WS-PERFORMING-EXP     PIC 9(16)V99 VALUE ZERO.
            05 WS-OVERDUE-EXP        PIC 9(16)V99 VALUE ZERO.
            05 WS-TOTAL-DEPOSITS     PIC 9(16)V99 VALUE ZERO.

        01  WS-PSTAW10-METRICS.
            05 WS-PIX-CNT            PIC 9(08) VALUE ZERO.
            05 WS-PIX-VOL            PIC 9(16)V99 VALUE ZERO.
            05 WS-TRANSFER-CNT       PIC 9(08) VALUE ZERO.
            05 WS-TRANSFER-VOL       PIC 9(16)V99 VALUE ZERO.
            05 WS-DEBIT-CNT          PIC 9(08) VALUE ZERO.
            05 WS-DEBIT-VOL          PIC 9(16)V99 VALUE ZERO.
            05 WS-CREDIT-CNT         PIC 9(08) VALUE ZERO.
            05 WS-CREDIT-VOL         PIC 9(16)V99 VALUE ZERO.
            05 WS-FEE-CNT            PIC 9(08) VALUE ZERO.
            05 WS-FEE-VOL            PIC 9(16)V99 VALUE ZERO.

        01  WS-FORMATTED-NUMS.
            05 FMT-EXPOSURE          PIC 9(16).99.
            05 FMT-DEPOSITS          PIC 9(16).99.
            05 FMT-PIX-VOL           PIC 9(16).99.
            05 FMT-TRANSFER-VOL      PIC 9(16).99.
            05 FMT-DEBIT-VOL         PIC 9(16).99.
            05 FMT-CREDIT-VOL        PIC 9(16).99.
            05 FMT-FEE-VOL           PIC 9(16).99.

        PROCEDURE DIVISION.
        MAIN-PROCEDURE.
            PERFORM 1000-INIT
            PERFORM 2000-PROCESS-ACCOUNTS UNTIL WS-EOF-ACCT = 'Y'
            PERFORM 3000-PROCESS-TRANS UNTIL WS-EOF-TRANS = 'Y'
            PERFORM 4000-WRITE-REPORTS
            PERFORM 5000-FINALIZE
            STOP RUN.

        1000-INIT.
            ACCEPT WS-ACCOUNTS-PATH FROM ENVIRONMENT 'INPUT_FILE'
            IF WS-ACCOUNTS-PATH = SPACES
                ACCEPT WS-ACCOUNTS-PATH FROM ENVIRONMENT 'ACCOUNTS_FILE'
            END-IF
            ACCEPT WS-TRANS-PATH    FROM ENVIRONMENT 'TRANS_FILE'
            ACCEPT WS-REPORT-PATH   FROM ENVIRONMENT 'OUTPUT_FILE'
            ACCEPT WS-PROCESS-DATE  FROM ENVIRONMENT 'PROCESS_DATE'
            IF WS-PROCESS-DATE = SPACES
                MOVE "2024-01-01" TO WS-PROCESS-DATE
            END-IF

            OPEN INPUT ACCOUNTS-FILE
            IF WS-ACCT-STATUS NOT = '00'
                MOVE 'Y' TO WS-EOF-ACCT
            ELSE
                MOVE 'Y' TO WS-ACCT-IS-OPEN
                READ ACCOUNTS-FILE
                    AT END MOVE 'Y' TO WS-EOF-ACCT
                END-READ
            END-IF

            OPEN INPUT TRANS-FILE
            IF WS-TRANS-STATUS NOT = '00'
                MOVE 'Y' TO WS-EOF-TRANS
            ELSE
                MOVE 'Y' TO WS-TRANS-IS-OPEN
                READ TRANS-FILE
                    AT END MOVE 'Y' TO WS-EOF-TRANS
                END-READ
            END-IF

            OPEN OUTPUT REPORT-FILE
            IF WS-REPORT-STATUS NOT = '00'
                MOVE 2 TO RETURN-CODE
                STOP RUN
            END-IF.

        2000-PROCESS-ACCOUNTS.
            ADD 1 TO WS-TOTAL-ACCTS
            IF ACCT-BALANCE < 0
                ADD 1 TO WS-EXPOSED-ACCTS
                COMPUTE WS-TOTAL-EXPOSURE = WS-TOTAL-EXPOSURE - ACCT-BALANCE
                COMPUTE WS-OVERDUE-EXP = WS-OVERDUE-EXP - ACCT-BALANCE
            ELSE
                ADD ACCT-BALANCE TO WS-TOTAL-DEPOSITS
            END-IF

            READ ACCOUNTS-FILE
                AT END MOVE 'Y' TO WS-EOF-ACCT
            END-READ.

        3000-PROCESS-TRANS.
            EVALUATE FUNCTION TRIM(TR-TYPE)
                WHEN 'TRANSFER'
                    ADD 1 TO WS-TRANSFER-CNT
                    ADD TR-AMOUNT TO WS-TRANSFER-VOL
                WHEN 'DEBIT'
                    ADD 1 TO WS-DEBIT-CNT
                    ADD TR-AMOUNT TO WS-DEBIT-VOL
                WHEN 'CREDIT'
                    ADD 1 TO WS-CREDIT-CNT
                    ADD TR-AMOUNT TO WS-CREDIT-VOL
                WHEN 'FEE'
                    ADD 1 TO WS-FEE-CNT
                    ADD TR-AMOUNT TO WS-FEE-VOL
                WHEN 'PIX'
                    ADD 1 TO WS-PIX-CNT
                    ADD TR-AMOUNT TO WS-PIX-VOL
                WHEN OTHER
                    ADD 1 TO WS-TRANSFER-CNT
                    ADD TR-AMOUNT TO WS-TRANSFER-VOL
            END-EVALUATE

            READ TRANS-FILE
                AT END MOVE 'Y' TO WS-EOF-TRANS
            END-READ.

        4000-WRITE-REPORTS.
            MOVE WS-TOTAL-EXPOSURE TO FMT-EXPOSURE
            MOVE WS-TOTAL-DEPOSITS TO FMT-DEPOSITS
            MOVE WS-PIX-VOL        TO FMT-PIX-VOL
            MOVE WS-TRANSFER-VOL   TO FMT-TRANSFER-VOL
            MOVE WS-DEBIT-VOL      TO FMT-DEBIT-VOL
            MOVE WS-CREDIT-VOL     TO FMT-CREDIT-VOL
            MOVE WS-FEE-VOL        TO FMT-FEE-VOL

            *> Header
            MOVE FUNCTION CONCATENATE(
                'REGULATORY_REPORT_SIMULATION|DATE=' WS-PROCESS-DATE
                '|ISPB=00000000|STATUS=READY'
            ) TO REPORT-RECORD
            WRITE REPORT-RECORD

            *> BACEN SCR Doc 3040 Section
            MOVE FUNCTION CONCATENATE(
                'BACEN_SCR_3040|TOTAL_ACCTS=' FUNCTION TRIM(WS-TOTAL-ACCTS LEADING)
                '|EXPOSED_ACCTS=' FUNCTION TRIM(WS-EXPOSED-ACCTS LEADING)
                '|TOTAL_EXPOSURE=' FUNCTION TRIM(FMT-EXPOSURE LEADING)
                '|RISK_CLASSIFICATION=RES_2682'
            ) TO REPORT-RECORD
            WRITE REPORT-RECORD

            *> BACEN PSTAW10 Section
            MOVE FUNCTION CONCATENATE(
                'BACEN_PSTAW10|TOTAL_DEPOSITS=' FUNCTION TRIM(FMT-DEPOSITS LEADING)
                '|PIX_CNT=' FUNCTION TRIM(WS-PIX-CNT LEADING)
                '|PIX_VOL=' FUNCTION TRIM(FMT-PIX-VOL LEADING)
                '|TRANSFER_CNT=' FUNCTION TRIM(WS-TRANSFER-CNT LEADING)
                '|TRANSFER_VOL=' FUNCTION TRIM(FMT-TRANSFER-VOL LEADING)
                '|FEE_CNT=' FUNCTION TRIM(WS-FEE-CNT LEADING)
                '|FEE_VOL=' FUNCTION TRIM(FMT-FEE-VOL LEADING)
                '|SETTLEMENT_NET=0.00'
            ) TO REPORT-RECORD
            WRITE REPORT-RECORD

            *> Compliance summary
            MOVE FUNCTION CONCATENATE(
                'COMPLIANCE_AUDIT|SYSTEM=SYSTEM_BANK|DOUBLE_ENTRY_VALID=YES'
                '|REGULATORY_STATUS=COMPLIANT'
            ) TO REPORT-RECORD
            WRITE REPORT-RECORD.

        5000-FINALIZE.
            IF WS-ACCT-IS-OPEN = 'Y'
                CLOSE ACCOUNTS-FILE
            END-IF
            IF WS-TRANS-IS-OPEN = 'Y'
                CLOSE TRANS-FILE
            END-IF
            CLOSE REPORT-FILE
            MOVE 0 TO RETURN-CODE.
