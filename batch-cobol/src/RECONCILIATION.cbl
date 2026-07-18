       IDENTIFICATION DIVISION.
       PROGRAM-ID. RECONCILIATION.
       AUTHOR.     SYSTEM-BANK.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRANS-FILE ASSIGN TO DYNAMIC WS-TRANS-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-TRANS-STATUS.
           SELECT LEDGER-FILE ASSIGN TO DYNAMIC WS-LEDGER-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-LEDGER-STATUS.
           SELECT REPORT-FILE  ASSIGN TO DYNAMIC WS-REPORT-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-REPORT-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  TRANS-FILE.
       01  TRANS-RECORD.
           05 TR-ID             PIC X(36).
           05 FILLER            PIC X(01).
           05 TR-ACCOUNT-ID     PIC X(36).
           05 FILLER            PIC X(01).
           05 TR-TYPE           PIC X(10).
           05 FILLER            PIC X(01).
           05 TR-AMOUNT         PIC 9(16)V99.

       FD  LEDGER-FILE.
       01  LEDGER-RECORD.
           05 LE-ID             PIC X(36).
           05 FILLER            PIC X(01).
           05 LE-TRANS-ID       PIC X(36).
           05 FILLER            PIC X(01).
           05 LE-ACCOUNT-ID     PIC X(36).
           05 FILLER            PIC X(01).
           05 LE-TYPE           PIC X(10).
           05 FILLER            PIC X(01).
           05 LE-AMOUNT         PIC 9(16)V99.

       FD  REPORT-FILE.
       01  REPORT-RECORD        PIC X(200).

       WORKING-STORAGE SECTION.
       01  WS-TRANS-PATH        PIC X(200).
       01  WS-LEDGER-PATH       PIC X(200).
       01  WS-REPORT-PATH       PIC X(200).
       
       01  WS-TRANS-STATUS      PIC X(02).
       01  WS-LEDGER-STATUS     PIC X(02).
       01  WS-REPORT-STATUS     PIC X(02).

       01  WS-EOF-TRANS         PIC X(01) VALUE 'N'.
       01  WS-EOF-LEDGER        PIC X(01) VALUE 'N'.
       01  WS-HAS-DIVERGENCE    PIC X(01) VALUE 'N'.
       
       01  WS-TOTAL-RECONCILED  PIC 9(10) VALUE ZERO.
       01  WS-TOTAL-DIVERGENT   PIC 9(10) VALUE ZERO.
       01  WS-PROCESS-DATE      PIC X(10).
       
       01  WS-CURR-TR-ID        PIC X(36).
       01  WS-SUM-DEBIT         PIC 9(16)V99 VALUE ZERO.
       01  WS-SUM-CREDIT        PIC 9(16)V99 VALUE ZERO.
       01  WS-COUNT-LEDGER      PIC 9(04) VALUE ZERO.

       PROCEDURE DIVISION.
       MAIN-PARA.
           ACCEPT WS-TRANS-PATH   FROM ENVIRONMENT 'TRANS_FILE'
           ACCEPT WS-LEDGER-PATH  FROM ENVIRONMENT 'LEDGER_FILE'
           ACCEPT WS-REPORT-PATH  FROM ENVIRONMENT 'OUTPUT_FILE'
           ACCEPT WS-PROCESS-DATE FROM ENVIRONMENT 'PROCESS_DATE'

           OPEN INPUT TRANS-FILE
           IF WS-TRANS-STATUS NOT = '00'
               MOVE 2 TO RETURN-CODE
               STOP RUN
           END-IF

           OPEN INPUT LEDGER-FILE
           IF WS-LEDGER-STATUS NOT = '00'
               MOVE 2 TO RETURN-CODE
               STOP RUN
           END-IF

           OPEN OUTPUT REPORT-FILE
           IF WS-REPORT-STATUS NOT = '00'
               MOVE 2 TO RETURN-CODE
               STOP RUN
           END-IF
           
           READ LEDGER-FILE
               AT END MOVE 'Y' TO WS-EOF-LEDGER
           END-READ

           PERFORM UNTIL WS-EOF-TRANS = 'Y'
               READ TRANS-FILE
                   AT END MOVE 'Y' TO WS-EOF-TRANS
                   NOT AT END
                       PERFORM PROCESS-TRANSACTION
               END-READ
           END-PERFORM

           PERFORM WRITE-SUMMARY

           CLOSE TRANS-FILE
           CLOSE LEDGER-FILE
           CLOSE REPORT-FILE

           IF WS-HAS-DIVERGENCE = 'Y'
               MOVE 1 TO RETURN-CODE
           ELSE
               MOVE 0 TO RETURN-CODE
           END-IF

           STOP RUN.

       PROCESS-TRANSACTION.
           MOVE TR-ID TO WS-CURR-TR-ID
           MOVE ZERO TO WS-SUM-DEBIT
           MOVE ZERO TO WS-SUM-CREDIT
           MOVE ZERO TO WS-COUNT-LEDGER
           
           PERFORM UNTIL WS-EOF-LEDGER = 'Y' OR LE-TRANS-ID > WS-CURR-TR-ID
               IF LE-TRANS-ID = WS-CURR-TR-ID
                   ADD 1 TO WS-COUNT-LEDGER
                   IF LE-TYPE(1:5) = 'DEBIT'
                       ADD LE-AMOUNT TO WS-SUM-DEBIT
                   END-IF
                   IF LE-TYPE(1:6) = 'CREDIT'
                       ADD LE-AMOUNT TO WS-SUM-CREDIT
                   END-IF
               END-IF
               READ LEDGER-FILE
                   AT END MOVE 'Y' TO WS-EOF-LEDGER
               END-READ
           END-PERFORM
           
           IF WS-COUNT-LEDGER NOT = 2 OR WS-SUM-DEBIT NOT = WS-SUM-CREDIT
               MOVE 'Y' TO WS-HAS-DIVERGENCE
               ADD 1 TO WS-TOTAL-DIVERGENT
               
               MOVE FUNCTION CONCATENATE(
                   'DIVERGENCE: TRANS_ID=' WS-CURR-TR-ID
                   ' COUNT=' WS-COUNT-LEDGER
                   ' DEBIT=' WS-SUM-DEBIT
                   ' CREDIT=' WS-SUM-CREDIT
               ) TO REPORT-RECORD
               WRITE REPORT-RECORD
           ELSE
               ADD 1 TO WS-TOTAL-RECONCILED
           END-IF.

       WRITE-SUMMARY.
           MOVE FUNCTION CONCATENATE(
               'DATE=' WS-PROCESS-DATE ','
               'TOTAL_RECONCILED=' FUNCTION TRIM(WS-TOTAL-RECONCILED LEADING) ','
               'TOTAL_DIVERGENT=' FUNCTION TRIM(WS-TOTAL-DIVERGENT LEADING)
           ) TO REPORT-RECORD
           WRITE REPORT-RECORD.
