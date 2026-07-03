# ADR 002 — RabbitMQ em vez de Kafka para mensageria

**Data:** 2024-01  
**Status:** Aceito

## Contexto

O sistema precisa de uma fila para desacoplar a API do processamento batch COBOL. As opções foram Kafka e RabbitMQ.

## Decisão

RabbitMQ foi escolhido.

## Consequências

**Positivas:**
- Modelo push (broker entrega mensagem ao consumer) reduz complexidade de offset management
- Dead-letter queues nativas — essencial para o fluxo de retry de transações com falha
- Management UI embutida facilita observabilidade em desenvolvimento
- Operacionalmente mais simples para volumes de transações de portfólio (< 10k msg/s)
- `persistent delivery mode = 2` garante durabilidade sem configuração extra de replicação

**Negativas:**
- Sem replay de mensagens (ao contrário do Kafka com retention)
- Menor throughput que Kafka para volumes de produção bancária real
- Para escala de Itaú/BB, Kafka seria a escolha correta — RabbitMQ foi escolhido por adequação ao escopo do projeto
