# ADR 001 — Rust em vez de Java/Spring Boot para a API

**Data:** 2024-01  
**Status:** Aceito

## Contexto

A camada de API precisa validar e rotear transações financeiras em tempo real com latência previsível. As opções avaliadas foram Java/Spring Boot (stack familiar) e Rust (Axum).

## Decisão

Rust com Axum foi escolhido.

## Consequências

**Positivas:**
- Segurança de memória garantida em tempo de compilação — elimina buffer overflows e use-after-free sem GC
- Throughput 3–5× maior que Spring Boot sob carga para endpoints simples de validação
- `rust_decimal::Decimal` previne erros de arredondamento monetário (`f64` é proibido)
- `Result<T, E>` torna tratamento de erros explícito — impossível ignorar falhas silenciosamente
- Binário único, sem JVM — imagem Docker menor e boot mais rápido

**Negativas:**
- Curva de aprendizado do borrow checker
- Ecossistema menor que Java para bibliotecas bancárias específicas
- Tempo de compilação maior em desenvolvimento
