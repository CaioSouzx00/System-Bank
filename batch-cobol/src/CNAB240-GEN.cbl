       IDENTIFICATION DIVISION.
       PROGRAM-ID. CNAB240-GEN.
       AUTHOR. System Bank.
       
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT INPUT-FILE ASSIGN TO "io/input/rust_input.dat"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-INPUT-STATUS.
           SELECT OUTPUT-FILE ASSIGN TO "io/output/cnab240.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-OUTPUT-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  INPUT-FILE.
       01  INPUT-RECORD.
           COPY ACCOUNT-RECORD.
           05  TRANSFER-BANK       PIC X(3).
           05  TRANSFER-DV-AGENCIA PIC X(1).
           05  TRANSFER-AMOUNT     PIC 9(18)V99.

       FD  OUTPUT-FILE.
       01  OUTPUT-RECORD         PIC X(240).

       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUS.
           05 WS-INPUT-STATUS    PIC X(2).
           05 WS-OUTPUT-STATUS   PIC X(2).

       01  WS-EOF-FLAG           PIC X VALUE 'N'.
           88  EOF-REACHED       VALUE 'Y'.

       01  WS-COUNTERS.
           05 WS-RECORD-SEQ      PIC 9(10) VALUE 1.
           05 WS-BATCH-RECORDS   PIC 9(6) VALUE 2.
           05 WS-TOTAL-RECORDS   PIC 9(6) VALUE 4.
           05 WS-TOTAL-AMOUNT    PIC 9(16)V99 VALUE ZEROS.
           
       01  WS-FILE-HEADER.
           05 FH-BANCO           PIC X(3) VALUE '999'.
           05 FH-LOTE            PIC X(4) VALUE '0000'.
           05 FH-TIPO            PIC X(1) VALUE '0'.
           05 FH-FILLER1         PIC X(232) VALUE SPACES.

       01  WS-BATCH-HEADER.
           05 BH-BANCO           PIC X(3) VALUE '999'.
           05 BH-LOTE            PIC X(4) VALUE '0001'.
           05 BH-TIPO            PIC X(1) VALUE '1'.
           05 BH-FILLER1         PIC X(232) VALUE SPACES.

       01  WS-SEGMENT-A.
           05 SA-BANCO-FAV       PIC X(3).
           05 SA-AGENCIA         PIC X(5).
           05 SA-DV-AGENCIA      PIC X(1).
           05 SA-SEQUENCIAL      PIC 9(10).
           05 SA-FILLER1         PIC X(53) VALUE SPACES.
           05 SA-VALOR           PIC 9(18)V99.
           05 SA-FILLER2         PIC X(148) VALUE SPACES.

       01  WS-BATCH-TRAILER.
           05 BT-BANCO           PIC X(3) VALUE '999'.
           05 BT-LOTE            PIC X(4) VALUE '0001'.
           05 BT-TIPO            PIC X(1) VALUE '5'.
           05 BT-FILLER1         PIC X(9) VALUE SPACES.
           05 BT-QTD-REGS        PIC 9(6).
           05 BT-TOTAL-VALOR     PIC 9(16)V99.
           05 BT-FILLER2         PIC X(199) VALUE SPACES.

       01  WS-FILE-TRAILER.
           05 FT-BANCO           PIC X(3) VALUE '999'.
           05 FT-LOTE            PIC X(4) VALUE '9999'.
           05 FT-TIPO            PIC X(1) VALUE '9'.
           05 FT-FILLER1         PIC X(9) VALUE SPACES.
           05 FT-QTD-LOTES       PIC 9(6) VALUE 1.
           05 FT-QTD-REGS        PIC 9(6).
           05 FT-FILLER2         PIC X(211) VALUE SPACES.

       PROCEDURE DIVISION.
       MAIN-PROCEDURE.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-RECORDS UNTIL EOF-REACHED
           PERFORM 3000-FINALIZE
           STOP RUN.

       1000-INITIALIZE.
           OPEN INPUT INPUT-FILE
           IF WS-INPUT-STATUS NOT = '00'
               DISPLAY 'ERRO AO ABRIR INPUT-FILE: ' WS-INPUT-STATUS
               STOP RUN
           END-IF
           
           OPEN OUTPUT OUTPUT-FILE
           IF WS-OUTPUT-STATUS NOT = '00'
               DISPLAY 'ERRO AO ABRIR OUTPUT-FILE: ' WS-OUTPUT-STATUS
               STOP RUN
           END-IF
           
           *> Write File Header
           WRITE OUTPUT-RECORD FROM WS-FILE-HEADER
           IF WS-OUTPUT-STATUS NOT = '00'
               DISPLAY 'ERRO AO ESCREVER FILE-HEADER'
               STOP RUN
           END-IF
           
           *> Write Batch Header
           WRITE OUTPUT-RECORD FROM WS-BATCH-HEADER
           IF WS-OUTPUT-STATUS NOT = '00'
               DISPLAY 'ERRO AO ESCREVER BATCH-HEADER'
               STOP RUN
           END-IF
           
           *> Read first record
           READ INPUT-FILE
               AT END SET EOF-REACHED TO TRUE
           END-READ.

       2000-PROCESS-RECORDS.
           *> Populate Segment A fields based on layout requirements
           MOVE TRANSFER-BANK TO SA-BANCO-FAV
           MOVE ACCT-AGENCY TO SA-AGENCIA
           MOVE TRANSFER-DV-AGENCIA TO SA-DV-AGENCIA
           MOVE WS-RECORD-SEQ TO SA-SEQUENCIAL
           MOVE TRANSFER-AMOUNT TO SA-VALOR
           
           *> Accumulate totals
           ADD TRANSFER-AMOUNT TO WS-TOTAL-AMOUNT
           ADD 1 TO WS-BATCH-RECORDS
           ADD 1 TO WS-TOTAL-RECORDS
           ADD 1 TO WS-RECORD-SEQ
           
           *> Write Segment A
           WRITE OUTPUT-RECORD FROM WS-SEGMENT-A
           IF WS-OUTPUT-STATUS NOT = '00'
               DISPLAY 'ERRO AO ESCREVER SEGMENTO-A'
               STOP RUN
           END-IF
           
           READ INPUT-FILE
               AT END SET EOF-REACHED TO TRUE
           END-READ.

       3000-FINALIZE.
           *> Write Batch Trailer
           MOVE WS-BATCH-RECORDS TO BT-QTD-REGS
           MOVE WS-TOTAL-AMOUNT TO BT-TOTAL-VALOR
           WRITE OUTPUT-RECORD FROM WS-BATCH-TRAILER
           IF WS-OUTPUT-STATUS NOT = '00'
               DISPLAY 'ERRO AO ESCREVER BATCH-TRAILER'
               STOP RUN
           END-IF
           
           *> Write File Trailer
           MOVE WS-TOTAL-RECORDS TO FT-QTD-REGS
           WRITE OUTPUT-RECORD FROM WS-FILE-TRAILER
           IF WS-OUTPUT-STATUS NOT = '00'
               DISPLAY 'ERRO AO ESCREVER FILE-TRAILER'
               STOP RUN
           END-IF
           
           CLOSE INPUT-FILE
           CLOSE OUTPUT-FILE.
