#!/usr/bin/env bash
set -euo pipefail

# Verifica se DATABASE_URL está definida
if [ -z "${DATABASE_URL:-}" ]; then
  echo "Erro: A variável de ambiente DATABASE_URL não está definida."
  echo "Exemplo de uso: DATABASE_URL=postgres://user:pass@localhost/db ./scripts/run-migrations.sh"
  exit 1
fi

MIGRATIONS_DIR="migrations"

if [ ! -d "$MIGRATIONS_DIR" ]; then
  echo "Erro: Diretório '$MIGRATIONS_DIR' não encontrado."
  exit 1
fi

echo "Iniciando a execução das migrations..."

# Verifica se o sqlx está instalado
if command -v sqlx >/dev/null 2>&1; then
  echo "Usando 'sqlx migrate run'..."
  # O próprio sqlx já cuida de exibir o progresso com nome das migrations e retorna exit code > 0 em falha.
  sqlx migrate run --source "$MIGRATIONS_DIR" --database-url "$DATABASE_URL"
else
  echo "Aviso: 'sqlx' não encontrado no PATH. Fazendo fallback para execução direta com psql..."
  
  if ! command -v psql >/dev/null 2>&1; then
    echo "Erro: 'psql' também não foi encontrado. Instale o sqlx-cli ou o client do postgresql."
    exit 1
  fi

  # Aplica cada migration, exibindo o nome de cada uma.
  # Utiliza ON_ERROR_STOP=1 para garantir que o script retorne código não-zero se alguma query falhar.
  for file in $(find "$MIGRATIONS_DIR" -maxdepth 1 -name '*.sql' | sort); do
    filename=$(basename "$file")
    echo "Aplicando migration: $filename"
    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$file"
  done
fi

echo "Todas as migrations foram aplicadas com sucesso!"
