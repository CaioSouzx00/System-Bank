# ADR 006 — Argon2id em vez de bcrypt/scrypt para hash de senhas

**Data:** 2024-03
**Status:** Aceito

## Contexto

A segurança das credenciais dos usuários no banco de dados é crítica para o projeto. Em caso de vazamento do banco de dados, precisamos de um mecanismo forte de hashing de senhas para mitigar ataques de força bruta, dicionário e uso de hardware especializado (ASICs/GPUs). Alternativas como `bcrypt` e `scrypt` foram avaliadas, além do `Argon2`, vencedor do Password Hashing Competition (PHC).

## Decisão

Utilizar **Argon2id** como o algoritmo padrão de hashing de senhas para todos os novos usuários e na autenticação, utilizando parâmetros apropriados para o contexto (time cost, memory cost e degree of parallelism). 

O `Argon2id` é preferível por combinar proteção tanto contra ataques de temporização (side-channel) baseados em cache (característica do Argon2i) quanto contra ataques baseados em hardware GPU/ASIC (característica do Argon2d).

## Consequências

**Positivas:**
- Forte proteção contra quebras de senhas usando hardware especializado.
- Flexibilidade no tuning: CPU, memória e paralelismo podem ser ajustados individualmente com a evolução do poder computacional.
- Considerado state-of-the-art e amplamente recomendado por entidades de segurança (OWASP).

**Negativas:**
- Maior consumo de memória do servidor e CPU durante a autenticação, intencional mas que deve ser balanceado para evitar ataques de negação de serviço (DoS).
- Necessita dependências externas mais modernas na API, que podem ter bibliotecas de build C subjacentes que afetam ligeiramente a portabilidade ou a complexidade do build Rust.
