      *> ============================================================
      *> Copybook: ACCOUNT-RECORD.cpy
      *> Estrutura compartilhada entre programas COBOL
      *> ============================================================
       01  ACCOUNT-RECORD.
           05 ACCT-ID          PIC X(36).
           05 ACCT-AGENCY      PIC X(04).
           05 ACCT-NUMBER      PIC X(10).
           05 ACCT-BALANCE     PIC S9(15)V99.
           05 ACCT-STATUS      PIC X(10).
           05 ACCT-CREATED     PIC X(10).
