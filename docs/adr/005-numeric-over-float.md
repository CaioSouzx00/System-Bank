# ADR 005 — NUMERIC/Decimal em vez de float para valores monetários

**Data:** 2024-02
**Status:** Aceito

## Contexto

Sistemas financeiros precisam lidar com valores monetários com exatidão rigorosa. Tipos de ponto flutuante (`float`, `f32`, `f64`) usam representação binária de frações (IEEE 754) que frequentemente resulta em imprecisões e erros de arredondamento (por exemplo, `0.1 + 0.2 = 0.30000000000000004`). Esses erros se acumulam em cálculos massivos como cálculo de juros e reconciliações, comprometendo o balanço financeiro e causando falhas em testes e auditorias.

## Decisão

Adotar estritamente tipos de precisão decimal exata em toda a stack, eliminando o uso de ponto flutuante:
- **Banco de Dados (PostgreSQL):** Utilizar `NUMERIC(15, 2)` (ou `DECIMAL`) para todos os valores monetários.
- **Backend API (Rust):** Utilizar a biblioteca `rust_decimal::Decimal` para desserialização, cálculos e persistência de dados. O uso de `f32` e `f64` é proibido para montantes financeiros (ver [ADR 001](./001-rust-over-java.md)).
- **Batch Processing (COBOL):** Utilizar PICTURE clauses com precisão exata, como `PIC S9(13)V99 COMP-3` (Decimal Compactado) ou campos numéricos equivalentes `PIC 9(13)V99`.

## Consequências

**Positivas:**
- Garantia de exatidão matemática nos cálculos financeiros, juros e reconciliações.
- Prevenção de perda financeira ou discrepâncias por erros de arredondamento.
- Conformidade com padrões contábeis e auditorias.

**Negativas:**
- Pequena redução no desempenho de cálculo matemático em comparação ao hardware nativo para `float`, mas irrelevante dado o ganho de corretude.
- Maior consumo de memória/disco nos tipos compactados/strings em relação aos binários float nativos.
- Overhead sintático em Rust para instanciar e manipular tipos de terceiros (`Decimal`).
