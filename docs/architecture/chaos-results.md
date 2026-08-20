# Resultados: Testes de Chaos Engineering

Este documento consolida os cenários de chaos engineering implementados no System-Bank e o comportamento esperado/observado do sistema sob essas condições.

## 1. PostgreSQL indisponível
**Cenário:** O banco de dados cai ou fica inacessível repentinamente (`docker pause`).
**Script:** `scripts/chaos/pg_unavailable.sh`
**Comportamento Observado:**
- A API Rust deve detectar a falha na conexão e retornar erro `503 Service Unavailable` ou `500 Internal Server Error` (dependendo do tipo da rota).
- Mensagens assíncronas que dependem do banco de dados (ex: processamento via worker) são mantidas na fila.
- Assim que o banco retorna, a API e os workers reconectam e processam as pendências normalmente.

## 2. RabbitMQ reinicia
**Cenário:** O broker de mensageria sofre um crash ou é reiniciado (`docker restart`).
**Script:** `scripts/chaos/rabbitmq_restart.sh`
**Comportamento Observado:**
- O worker COBOL e a API detectam a queda da conexão.
- O mecanismo de reconexão automática das bibliotecas (tanto no lado da API Rust quanto no worker) atua, tentando restabelecer a conexão.
- Nenhuma mensagem "em trânsito" deve ser confirmada (ACK) sem processamento, evitando perda de dados.
- O processamento retoma quando o broker volta a ficar on-line.

## 3. COBOL worker trava
**Cenário:** O processo do worker responsável pelo processamento de transações pesadas sofre um hang / deadlock (`SIGSTOP`).
**Script:** `scripts/chaos/cobol_worker_hang.sh`
**Comportamento Observado:**
- As requisições continuam sendo aceitas pela API e publicadas na fila do RabbitMQ.
- Sem o worker ativo, as mensagens se acumulam.
- Caso possuam um TTL (Time-To-Live) ou atinjam limite de retentativas sem ACK (como configurado pelas políticas), elas podem ser movidas para a Dead Letter Queue (DLQ).
- Quando o worker retorna (`SIGCONT`), o consumo regular é restabelecido.

## 4. Latência de rede simulada
**Cenário:** Uma alta latência repentina na rede é injetada na API.
**Script:** `scripts/chaos/network_latency.sh`
**Comportamento Observado:**
- Respostas da API demoram significativamente mais (aumento > 500ms).
- O rate limiting continua atuando conforme esperado.
- Clientes com timeouts muito curtos podem falhar, o que é um comportamento correto de fail-fast.
- Sem corrupção de estado interno; ao cessar a latência, a API retoma a performance nominal.
