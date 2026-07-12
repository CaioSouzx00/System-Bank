# Batch COBOL

Este diretório contém os programas COBOL em lote executados pelo sistema, incluindo o gerador de arquivos de remessa bancária.

## Integração Rust-COBOL (CNAB240-GEN)

O worker Rust interage com o programa COBOL `CNAB240-GEN` da seguinte forma:

### 1. Preparação dos Dados de Entrada
O Rust deve gerar um arquivo sequencial contendo os registros a serem incluídos no CNAB. O arquivo deve ser salvo em `io/input/rust_input.dat` (relativo ao diretório de execução do COBOL).

O layout de cada linha do arquivo de entrada segue a estrutura do copybook `ACCOUNT-RECORD` seguida pelo valor da transferência:

| Campo | Tamanho (Bytes) | Formato | Descrição |
| :--- | :--- | :--- | :--- |
| **ACCOUNT-ID** | 36 | Alfanumérico | UUID da conta |
| **AGENCY** | 4 | Alfanumérico | Agência da conta |
| **ACCOUNT-NUMBER** | 10 | Alfanumérico | Número da conta |
| **BALANCE** | 17 | Numérico (S9(15)V99) | Saldo da conta |
| **STATUS** | 10 | Alfanumérico | Status da conta (ex: ACTIVE) |
| **CREATED** | 10 | Alfanumérico | Data de criação (AAAA-MM-DD) |
| **TRANSFER-BANK** | 3 | Alfanumérico | Código do banco favorecido |
| **TRANSFER-DV-AGENCIA** | 1 | Alfanumérico | Dígito verificador da agência |
| **TRANSFER-AMOUNT** | 18 | Numérico (9(16)V99)| Valor da transferência em centavos (sem vírgula/ponto) |

*(Tamanho total do registro: 109 bytes por linha)*

### 2. Execução do Binário
O Rust deve invocar o programa COBOL compilado. É obrigatório exportar a variável de ambiente `COB_LS_FIXED=Y` para evitar que o GnuCOBOL trunque os espaços em branco no final das linhas de 240 posições.

Comando a ser executado via `std::process::Command` (certifique-se de injetar a variável de ambiente no processo):
```rust
use std::process::Command;

let status = Command::new("./bin/CNAB240-GEN")
    .env("COB_LS_FIXED", "Y")
    .current_dir("batch-cobol")
    .status()
    .expect("Falha ao executar CNAB240-GEN");
```

### 3. Leitura da Saída
Após a execução bem-sucedida, o COBOL gerará o arquivo formatado segundo o padrão FEBRABAN CNAB 240 em:
`io/output/cnab240.txt`

O Rust pode ler e enviar este arquivo para o SFTP do banco.
