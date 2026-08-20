# ADR 007 — Estratégia de Dead-Letter Queue (DLQ) e Reprocessamento Manual

**Data:** 2024-04
**Status:** Aceito

## Contexto

Eventos de negócios cruciais (como transações entre contas) trafegam por RabbitMQ (ver [ADR 002](./002-rabbitmq-over-kafka.md)). Ocasionalmente, consumidores falham ao processar essas mensagens devido a indisponibilidades sistêmicas, erros de formato ou bugs na lógica de negócio. Sem uma estratégia adequada para lidar com as falhas definitivas após as retentativas (retries), há o risco de perda de mensagens críticas (silently dropping) ou bloqueio contínuo da fila principal (head-of-line blocking).

## Decisão

Adotar o uso de **Dead-Letter Exchanges (DLX) e Dead-Letter Queues (DLQ)** do RabbitMQ, acompanhado de uma estratégia de reprocessamento manual:

1. **Retries:** Configurar retentativas curtas com backoff (no lado do consumidor ou com delayed exchanges) para falhas transitórias.
2. **Rejeição:** Após exceder o limite de retentativas ou em caso de erro fatal/não-transitório, a mensagem será rejeitada e não será requeued (reencaminhada) à mesma fila (`basic.reject`/`nack` com `requeue=false`).
3. **Encaminhamento DLQ:** A fila de origem será configurada com um `x-dead-letter-exchange` que roteará a mensagem descartada para uma DLQ correspondente.
4. **Reprocessamento:** As mensagens acumuladas na DLQ não serão reprocessadas automaticamente (evitando *poison pill loops*). Serão analisadas manualmente pela equipe de operações ou por ferramentas e, quando o bug for corrigido ou o sistema restabelecido, movidas de volta à fila original ou exchange usando plugins do RabbitMQ (como Shovel).

## Consequências

**Positivas:**
- Garantia de que nenhuma mensagem financeira é silenciosamente perdida após falha.
- Fila principal não fica bloqueada tentando processar mensagens erradas ciclicamente.
- Facilidade na investigação das mensagens falhas (fica isolado na DLQ com os headers originais contendo os motivos do envio à DLQ).

**Negativas:**
- Aumento da complexidade na configuração inicial das filas e exchanges (topologia do RabbitMQ).
- Necessidade de esforço operacional para monitorar as DLQs e intervir manualmente para corrigir ou mover as mensagens (não é um reprocessamento fully-automated).
