# ADR 009 — Painel Operacional de Reconciliação Contábil e Auditoria

**Data:** 2026-10  
**Status:** Aceito

## Contexto

A integridade do core bancário exige que a equação fundamental das partidas dobradas (`Σ Débitos == Σ Créditos`) seja continuamente monitorada em tempo real, prevenindo desvios entre os saldos das contas e os lançamentos do razão (`ledger_entries`), além de detectar eventuais transações órfãs sem lançamento contábil.

## Decisão

Implementar um painel operacional unificado de reconciliação contábil composto por:
1. Endpoint JSON `/operations/reconciliation/metrics` fornecendo telemetria contábil em tempo real;
2. Interface web moderna e responsiva servida em `/operations/reconciliation/dashboard`, com visualização de métricas de equilíbrio contábil, integridade de transações, simulações BACEN e execução de lotes COBOL;
3. Dashboards Grafana provisionados (`batch-reconciliation.json`) integrados com PostgreSQL e Loki para monitoramento contínuo em produção.

## Consequências

**Positivas:**
- Visibilidade imediata de qualquer assimetria contábil no livro-razão;
- Detecção instantânea de transações órfãs ou saldos discrepantes;
- Operadores conseguem acionar simulações de juros compostos, CNAB 240 e BACEN SCR/PSTAW10 em uma única tela.

**Negativas:**
- Pequeno overhead de consultas analíticas na base do ledger (mitigado por índices dedicados).
