      *> ============================================================
      *> FEE-CALC.cbl — Cálculo de Tarifas por Tipo de Operação
      *> ============================================================
       IDENTIFICATION DIVISION.
       PROGRAM-ID. FEE-CALC.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRANS-FILE ASSIGN TO DYNAMIC WS-INPUT-PATH
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT FEE-OUT-FILE ASSIGN TO DYNAMIC WS-OUTPUT-PATH
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD  TRANS-FILE.
       01  TF-RECORD.
           05 TF-TRANS-ID      PIC X(36).
           05 FILLER           PIC X(01).
           05 TF-ACCOUNT-ID    PIC X(36).
           05 FILLER           PIC X(01).
           05 TF-TRANS-TYPE    PIC X(10).

       FD  FEE-OUT-FILE.
       01  FO-RECORD           PIC X(150).

       WORKING-STORAGE SECTION.
       01  WS-INPUT-PATH       PIC X(200).
       01  WS-OUTPUT-PATH      PIC X(200).
       01  WS-EOF              PIC X(01) VALUE 'N'.

       01  WS-FEE-VALUES.
           05 FILLER PIC X(28) VALUE 'TRANSFER  000000000000000050'.
           05 FILLER PIC X(28) VALUE 'DEBIT     000000000000000030'.
           05 FILLER PIC X(28) VALUE 'CREDIT    000000000000000000'.
           05 FILLER PIC X(28) VALUE 'FEE       000000000000000000'.
       
       01  WS-FEE-TABLE REDEFINES WS-FEE-VALUES.
           05 T-ENTRY OCCURS 4 TIMES INDEXED BY T-IDX.
              10 T-OP-TYPE     PIC X(10).
              10 T-FEE         PIC 9(16)V99.

       01  WS-FOUND-FEE        PIC 9(16)V99.
       01  WS-FEE-OUT-FMT      PIC 9(18).

       PROCEDURE DIVISION.
       MAIN-PARA.
           ACCEPT WS-INPUT-PATH  FROM ENVIRONMENT 'TRANS_FILE'
           ACCEPT WS-OUTPUT-PATH FROM ENVIRONMENT 'OUTPUT_FILE'

           OPEN INPUT  TRANS-FILE
           OPEN OUTPUT FEE-OUT-FILE

           PERFORM UNTIL WS-EOF = 'Y'
               READ TRANS-FILE
                   AT END MOVE 'Y' TO WS-EOF
                   NOT AT END PERFORM PROCESS-TRANS
               END-READ
           END-PERFORM

           CLOSE TRANS-FILE
           CLOSE FEE-OUT-FILE
           STOP RUN.

       PROCESS-TRANS.
           SET T-IDX TO 1
           SEARCH T-ENTRY
               AT END
                   *> Tipo não encontrado, ignorar ou zerar tarifa
                   MOVE 0 TO WS-FOUND-FEE
               WHEN T-OP-TYPE(T-IDX) = TF-TRANS-TYPE
                   MOVE T-FEE(T-IDX) TO WS-FOUND-FEE
           END-SEARCH

           IF WS-FOUND-FEE > 0
               COMPUTE WS-FEE-OUT-FMT = WS-FOUND-FEE * 100
               MOVE FUNCTION CONCATENATE(
                   TF-ACCOUNT-ID ','
                   TF-TRANS-ID ','
                   WS-FEE-OUT-FMT ','
                   'FEE'
               ) TO FO-RECORD
               WRITE FO-RECORD
           END-IF.
