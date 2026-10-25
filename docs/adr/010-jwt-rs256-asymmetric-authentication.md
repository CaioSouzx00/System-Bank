# ADR 010: Autenticação JWT Assimétrica com RS256 (Resource Server vs IdP)

**Data:** 2024-01  
**Status:** Aceito

## Contexto

Em arquiteturas bancárias e financeiras, a integridade da autenticação e a segregação de responsabilidades são pilares inegociáveis. Inicialmente, cogitou-se o uso de JWT com assinatura simétrica (HS256 com segredo compartilhado `JWT_SECRET`). 

Entretanto, assinaturas simétricas impõem graves riscos em ambientes de microsserviços e sistemas críticos:
1. **Quebra de Segregação:** Qualquer serviço que precise validar um token precisa conhecer o mesmo segredo compartilhado. Se um serviço consumidor for comprometido, um atacante pode forjar tokens arbitrários com privilégios de `ADMIN` para qualquer conta.
2. **Impossibilidade de Descentralização Segura:** O emissor do token (Identity Provider / Auth Server) e os validadores (Resource Servers) ficam acoplados pelo mesmo segredo.

## Decisão

Adotou-se o padrão de **Criptografia Assimétrica com algoritmo RS256** (RSA Signature with SHA-256):

1. **Separação de Papéis (Resource Server vs IdP):**
   - **Emissor (IdP / Auth Server):** Detém a chave privada RSA (2048+ bits) em ambiente isolado (HSM / Vault / KMS) e é o único componente autorizado a assinar novos tokens.
   - **API Rust (Resource Server):** Detém **apenas** a chave pública RSA (`JWT_PUBLIC_KEY` / `JWT_PUBLIC_KEY_B64`). A API apenas valida a integridade, autenticidade e expiração dos tokens recebidos nos cabeçalhos `Authorization: Bearer <token>`. Em hipótese alguma a API possui ou armazena chaves privadas.
2. **Formato de Distribuição das Chaves:**
   - Suporte a chaves públicas PEM injetadas diretamente ou via Base64 (`JWT_PUBLIC_KEY_B64`), eliminando problemas comuns de quebra de linhas e formatação em containers Docker, Kubernetes e CI/CD.
   - Script automatizado (`scripts/generate-jwt-keys.sh`) para gerar pares de chaves de desenvolvimento e injetar a chave pública no `.env` local.
3. **Validação Estrita:**
   - Validação obrigatória de expiração (`exp`), emissão (`iat`), identificador do sujeito (`sub` UUID) e controle de acesso baseado em papéis (`role`: `CLIENT`, `OPERATOR`, `ADMIN`).

## Consequências

- **Positivas:**
  - **Zero Trust & Menor Superfície de Ataque:** Mesmo no pior cenário de comprometimento da API ou leitura indevida das variáveis de ambiente, o atacante obtém apenas a chave pública, sendo matematicamente impossível forjar tokens válidos.
  - **Alinhamento Arquitetural:** Compatibilidade nativa com padrões abertos da indústria (OAuth 2.0, OpenID Connect, JWKS).
  - **Facilidade Operacional:** Chave pública pode ser distribuída abertamente para múltiplos microsserviços sem risco criptográfico.

- **Negativas:**
  - Custo computacional de validação de assinatura RSA ligeiramente superior ao HMAC simétrico (desprezível frente aos ganhos de segurança e mitigado por cache e otimização em Rust).
