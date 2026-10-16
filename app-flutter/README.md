# 🏦 System-Bank App (Flutter)

Aplicativo bancário mobile-first, responsivo para tablet e web, desenvolvido em **Flutter 3.24+ / Dart 3.5+** para consumo do backend de core banking **System-Bank** (Rust Axum + GnuCOBOL 3.2 + RabbitMQ + PostgreSQL 16).

---

## ✨ Destaques de UX/UI & Engenharia

- 🎨 **Design System Institucional:** Inspirado em Nubank, Inter, Cora e Stripe Dashboard.
- 🌓 **Suporte Completo a Dark Mode:** Custom `BankThemeExtension` com paleta `#820AD1` (Purple), `#00D09C` (Success Green), contrastes elevados e acessibilidade.
- 🗂️ **Arquitetura Feature-First + Clean Architecture:** Separação estrita entre `presentation`, `domain` e `data`.
- ⚡ **State Management & DI:** Riverpod 2.x com `StateNotifier` e injeção de dependências desacoplada.
- 🧭 **Roteamento Avançado:** `go_router` com `StatefulShellRoute.indexedStack`, Guards de Autenticação e Guards de Role (`CLIENT`, `OPERATOR`, `ADMIN`).
- 📡 **Networking Resiliente:** `dio` com `AuthInterceptor` (Bearer token RS256), auto-logout em 401, retry exponencial e timeout configurável.
- ⚡ **Idempotência & Event-Driven:** Geração automática de `correlation_id` (UUID v4) em toda movimentação financeira e acompanhamento em tempo real de `PENDING` (202 Accepted) para `PROCESSED` ou `FAILED`.
- 💸 **Pix Completo:** Gestão de chaves BACEN (CPF, E-mail, Celular, EVP aleatória), QR Code dinâmico/estático, Copia e Cola e confirmação em 2 etapas.
- 📑 **Extrato Flexível:** Filtros por período (Hoje, 7d, 30d, 90d, Personalizado), busca instantânea e exportação nativa em **JSON** e **OFX**.
- 📊 **Painel Operacional para Staff:** Acesso exclusivo para `OPERATOR` e `ADMIN` para auditoria do Double-Entry Ledger, métricas de custódia e acionamento de jobs COBOL (`RECONCILIATION.cbl`).
- 📴 **Offline-First Leve:** Caching local com `shared_preferences` para saldo e extrato, e `flutter_secure_storage` para credenciais.

---

## 🏗️ Estrutura de Pastas (Feature-First)

```text
app-flutter/
├── lib/
│   ├── main.dart                          # Entrypoint com ProviderScope e Localizations pt-BR
│   ├── core/
│   │   ├── config/env_config.dart         # URLs e timeouts por plataforma (Web / Android / iOS)
│   │   ├── constants/                     # Cores, Tipografia Inter (tabular figures) e Dimensões
│   │   ├── errors/                        # AppException e Failures de domínio
│   │   ├── network/                       # ApiClient Dio, AuthInterceptor e Endpoints
│   │   ├── storage/                       # FlutterSecureStorage e SharedPreferences Cache
│   │   ├── theme/                         # Material 3 Light/Dark & BankThemeExtension
│   │   ├── utils/                         # CurrencyFormatter, DateFormatter, IdGenerator, PixValidator
│   │   └── widgets/                       # BankButton, BankCard, BankTextField, BankStatusBadge, etc.
│   ├── routes/
│   │   ├── app_routes.dart                # Constantes de rotas
│   │   ├── app_router.dart                # GoRouter com Guards de Auth e Role
│   │   └── scaffold_with_nav_bar.dart     # Responsive BottomBar (Mobile) / NavigationRail (Tablet/Web)
│   └── features/
│       ├── auth/                          # Login, Registro, Biometria, Token manager, Roles
│       ├── accounts/                      # Listagem multi-contas, Abertura e Simulação de Juros
│       ├── dashboard/                     # Card de saldo Nubank-like, Ações rápidas e Extrato recente
│       ├── pix/                           # Hub Pix, Envio 2 etapas, Gestão de chaves e QR Code
│       ├── transactions/                  # Débito, Crédito, Transferência, Status tracking e Extrato
│       ├── operations/                    # Painel de Reconciliação (OPERATOR e ADMIN)
│       └── profile/                       # Configurações, Tema, Biometria e Switch de perfis
```

---

## 🚀 Como Executar

### Pré-requisitos
- Flutter SDK 3.24.0 ou superior instalado e configurado no PATH
- Backend do **System-Bank** em execução local (`http://localhost:8080`)

### 1. Instalar as dependências
```bash
cd app-flutter
flutter pub get
```

### 2. Executar no Navegador (Web)
```bash
flutter run -d chrome
```

### 3. Executar no Android Emulator
No emulador Android, a rota padrão para o host da máquina é mapeada automaticamente para `http://10.0.2.2:8080`:
```bash
flutter run -d emulator-name
```

### 4. Executar no Windows Desktop
```bash
flutter run -d windows
```

---

## 🔌 Conexão com o Backend Rust (Axum)

1. Certifique-se de que o backend Docker do System-Bank está rodando:
   ```bash
   # Na raiz do repositório System-Bank:
   docker compose -f infra/docker/docker-compose.yml up -d
   bash scripts/run-migrations.sh
   ```
2. O aplicativo possui um painel em **Perfil → Configurações → Servidor do Backend** onde você pode testar a conectividade em tempo real com o endpoint `/health` ou alterar a URL base da API a qualquer momento.

---

## 🎭 Alternador Rápido de Perfis (Roles)

Para facilitar a validação e demonstração de todas as funcionalidades de compliance bancário:
- Na tela de **Login** ou na tela de **Perfil**, selecione diretamente:
  - 👤 **Cliente (CLIENT):** Acesso à Home, PIX, Transferências, Abertura de Contas e Extrato.
  - 🛠️ **Operador (OPERATOR):** Acesso a todas as funções de cliente + **Painel de Reconciliação** e monitoramento do ledger.
  - 🔒 **Administrador (ADMIN):** Acesso total, incluindo auditoria, bloqueio de contas e disparo manual de jobs de reconciliação em lote COBOL.
