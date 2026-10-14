# ADR 008 — Simulação e Geração de Relatórios Regulatórios BACEN (SCR 3040 e PSTAW10)

**Data:** 2026-10  
**Status:** Aceito

## Contexto

Instituições financeiras e de pagamento reguladas pelo Banco Central do Brasil (BACEN) devem prestar contas periódicas de suas carteiras de crédito, risco e liquidez. O System-Bank necessitava de um motor para simular e gerar os relatórios regulatórios:
1. **BACEN SCR (Documento 3040):** Posição de risco e provisionamento de crédito segundo a Resolução CMN 2682/1999;
2. **BACEN PSTAW10:** Demonstrativo diário e mensal de instrumentos de pagamentos (PIX, TED, tarifas e custódia).

## Decisão

Adotar uma arquitetura integrada combinando a força de processamento em lote do COBOL com a agilidade dos serviços em Rust:
1. Programa batch legado `REGULATORY-REPORT.cbl` para processamento sequencial de contas e transações;
2. Serviço na API Rust (`regulatory_service.rs`) expondo endpoints REST (`/regulatory/scr`, `/regulatory/pstaw10`, `/regulatory/reports`);
3. Suporte a exportação tanto em JSON moderno quanto em XML estruturado compatível com o Catálogo de Documentos do BACEN;
4. Persistência em tabela de auditoria regulatória (`regulatory_reports`) com checksum criptográfico SHA-256.

## Consequências

**Positivas:**
- Classificação automática de faixas de risco (A até H) e cálculo exato de provisão para saldo devedor;
- Auditoria de liquidação líquida multilateral com partidas dobradas comprovando soma zero;
- Integração transparente entre o pipeline em lote e a camada consumida por auditores e reguladores.

**Negativas:**
- Complexidade adicional na manutenção das tabelas de alíquotas de provisionamento.
