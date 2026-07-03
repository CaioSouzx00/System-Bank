      *> ============================================================
      *> INTEREST-CALC.cbl — Cálculo de Juros Compostos
      *> Regime: capitalização composta diária
      *> Entrada: contas com saldo devedor e taxa vigente
      *> ============================================================
       IDENTIFICATION DIVISION.
       PROGRAM-ID. INTEREST-CALC.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT DEBIT-ACCOUNTS ASSIGN TO DYNAMIC WS-INPUT-PATH
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT INTEREST-OUT   ASSIGN TO DYNAMIC WS-OUTPUT-PATH
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD  DEBIT-ACCOUNTS.
       01  DA-RECORD.
           05 DA-ACCOUNT-ID    PIC X(36).
           05 FILLER           PIC X(01).
           05 DA-BALANCE       PIC S9(15)V99.
           05 FILLER           PIC X(01).
           05 DA-RATE          PIC 9(03)V9(06).   *> Taxa anual com 6 dec
           05 FILLER           PIC X(01).
           05 DA-DAYS          PIC 9(04).          *> Dias em atraso

       FD  INTEREST-OUT.
       01  IO-RECORD           PIC X(200).

       WORKING-STORAGE SECTION.
       01  WS-INPUT-PATH       PIC X(200).
       01  WS-OUTPUT-PATH      PIC X(200).
       01  WS-EOF              PIC X(01) VALUE 'N'.
       01  WS-DAILY-RATE       PIC 9(03)V9(10).
       01  WS-INTEREST         PIC S9(15)V99.
       01  WS-COMPOUND-FACTOR  PIC 9(03)V9(10).

       PROCEDURE DIVISION.
       MAIN-PARA.
           ACCEPT WS-INPUT-PATH  FROM ENVIRONMENT 'INPUT_FILE'
           ACCEPT WS-OUTPUT-PATH FROM ENVIRONMENT 'OUTPUT_FILE'

           OPEN INPUT  DEBIT-ACCOUNTS
           OPEN OUTPUT INTEREST-OUT

           PERFORM UNTIL WS-EOF = 'Y'
               READ DEBIT-ACCOUNTS
                   AT END MOVE 'Y' TO WS-EOF
                   NOT AT END PERFORM CALC-INTEREST
               END-READ
           END-PERFORM

           CLOSE DEBIT-ACCOUNTS
           CLOSE INTEREST-OUT
           STOP RUN.

       CALC-INTEREST.
           *> Taxa diária = (1 + taxa_anual)^(1/365) - 1
           COMPUTE WS-DAILY-RATE =
               (1 + DA-RATE / 100) ** (1 / 365) - 1

           *> Fator composto = (1 + taxa_diaria)^dias
           COMPUTE WS-COMPOUND-FACTOR =
               (1 + WS-DAILY-RATE) ** DA-DAYS

           COMPUTE WS-INTEREST = DA-BALANCE *
               (WS-COMPOUND-FACTOR - 1)

           MOVE FUNCTION CONCATENATE(
               DA-ACCOUNT-ID ','
               FUNCTION TRIM(WS-INTEREST LEADING)
           ) TO IO-RECORD
           WRITE IO-RECORD.
