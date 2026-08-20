# ADR 004: mTLS para Comunicação Interna (API e COBOL Worker)

**Data:** 2024-01
**Status:** Aceito
## Contexto
O projeto tem como premissa de arquitetura um forte viés de segurança. A comunicação interna, especialmente na atualização de status de execuções batch (COBOL), antes utilizava acesso direto ao banco de dados via cliente psql. Embora isso funcionasse, mantinha uma superfície de ataque considerável, exigindo as credenciais do banco dentro do worker, e dificultando auditoria e observabilidade.

Além disso, é requisito do negócio garantir que todos os componentes comuniquem-se de forma segura e autenticada via mTLS (Autenticação Mútua TLS), abolindo o conceito de confiança cega na rede (Zero Trust network baseline).

## Decisão
1. **Autoridade Certificadora Interna**: Criamos uma CA interna focada em emitir certificados de infraestrutura.
2. **Uso de mTLS**: A comunicação entre componentes (ex. COBOL Worker reportando o resultado de um job para a API Rust) passa a utilizar HTTPS. O servidor (API Rust) exige e valida o certificado do cliente. O cliente (Worker) valida o certificado do servidor pela CA.
3. **Distribuição via Variáveis de Ambiente**: Os certificados são codificados em Base64 (`CA_CERT_B64`, `SERVER_CERT_B64`, `SERVER_KEY_B64`, `CLIENT_CERT_B64`, `CLIENT_KEY_B64`) e injetados via arquivo `.env` para o Docker Compose, facilitando a rotação sem exigir reconstrução das imagens.
4. **Substituição do `psql` por HTTP**: O `run-job.sh` do COBOL passou a usar `curl` contra um novo endpoint `/internal/jobs/callback` da API, reduzindo os privilégios do container do worker que não precisa mais acessar o banco de dados diretamente.

## Consequências
- **Positivas:**
  - Melhor controle de acesso (Zero Trust).
  - Remoção das credenciais diretas do Postgres no `batch-cobol`.
  - Melhor capacidade de rastrear conexões via certificados x509.
  - Conformidade com requisitos de segurança e auditoria da Milestone v0.4.

- **Negativas:**
  - Complexidade adicional no gerenciamento e rotação de certificados.
  - Sobrecarga (overhead) computacional do hand-shake TLS (irrelevante para o volume de batching planejado, mas existente).
