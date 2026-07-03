# ADR 003 — Integração COBOL via subprocesso em vez de FFI

**Data:** 2024-01  
**Status:** Aceito

## Contexto

O worker Rust precisa invocar programas COBOL compilados. As opções foram FFI direta (chamar funções COBOL como biblioteca C) e subprocesso (`std::process::Command`).

## Decisão

Integração via subprocesso com troca de arquivos de entrada/saída.

## Consequências

**Positivas:**
- Isolamento de processo — um crash no programa COBOL não derruba o worker Rust
- Sem complexidade de FFI e linking entre runtimes diferentes
- Reflete o modelo real de integração em mainframes (JCL submete jobs com input/output datasets)
- Facilita testes: basta mockar os arquivos de entrada/saída
- Permite atualizar programas COBOL independentemente do worker

**Negativas:**
- Overhead de I/O de disco para arquivos de entrada/saída
- Latência maior que FFI para jobs frequentes
- Para integração com mainframe real (IBM z/OS), seria necessário MQ Series ou CICS Web Services — o subprocesso é uma simplificação válida para o escopo do portfólio
