# Architecture Decision Records

Este diretório contém as decisões de arquitetura do projeto, no formato ADR (Architecture Decision Record).

Cada arquivo documenta **o contexto, a decisão e as consequências** de uma escolha técnica relevante — seguindo o padrão de Michael Nygard.

## Índice

| ADR | Título | Status |
|-----|--------|--------|
| [001](./001-rust-over-java.md) | Rust em vez de Java/Spring Boot para a API | Aceito |
| [002](./002-rabbitmq-over-kafka.md) | RabbitMQ em vez de Kafka para mensageria | Aceito |
| [003](./003-cobol-subprocess.md) | Integração COBOL via subprocesso em vez de FFI | Aceito |
| [004](./004-mtls-internal.md) | mTLS para Comunicação Interna (API e COBOL Worker) | Aceito |
| [005](./005-numeric-over-float.md) | NUMERIC/Decimal em vez de float para valores monetários | Aceito |
| [006](./006-argon2id-password-hashing.md) | Argon2id em vez de bcrypt/scrypt para hash de senhas | Aceito |
| [007](./007-rabbitmq-dlq-strategy.md) | Estratégia de Dead-Letter Queue e reprocessamento manual | Aceito |
