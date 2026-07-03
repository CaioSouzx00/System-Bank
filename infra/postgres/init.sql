-- Inicialização do banco em ambiente de desenvolvimento
-- Executado automaticamente pelo entrypoint do container postgres

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Configurações de performance para desenvolvimento
ALTER SYSTEM SET log_min_duration_statement = '100ms';
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
