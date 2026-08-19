#!/usr/bin/env bash
set -e

CERTS_DIR="infra/docker/certs"
ENV_FILE="infra/docker/.env"

mkdir -p "$CERTS_DIR"

echo "Gerando CA..."
openssl req -x509 -newkey rsa:4096 -days 3650 -nodes \
    -keyout "$CERTS_DIR/ca.key" \
    -out "$CERTS_DIR/ca.crt" \
    -subj "/C=BR/ST=SP/L=SaoPaulo/O=SystemBank/OU=Security/CN=InternalCA"

echo "Gerando Certificado do Servidor (API Rust)..."
openssl req -newkey rsa:2048 -nodes \
    -keyout "$CERTS_DIR/server.key" \
    -out "$CERTS_DIR/server.csr" \
    -subj "/C=BR/ST=SP/L=SaoPaulo/O=SystemBank/OU=API/CN=system-bank-api"
openssl x509 -req -in "$CERTS_DIR/server.csr" -CA "$CERTS_DIR/ca.crt" -CAkey "$CERTS_DIR/ca.key" -CAcreateserial \
    -out "$CERTS_DIR/server.crt" -days 365 -sha256

echo "Gerando Certificado do Cliente (COBOL Worker)..."
openssl req -newkey rsa:2048 -nodes \
    -keyout "$CERTS_DIR/client.key" \
    -out "$CERTS_DIR/client.csr" \
    -subj "/C=BR/ST=SP/L=SaoPaulo/O=SystemBank/OU=Worker/CN=system-bank-cobol"
openssl x509 -req -in "$CERTS_DIR/client.csr" -CA "$CERTS_DIR/ca.crt" -CAkey "$CERTS_DIR/ca.key" -CAcreateserial \
    -out "$CERTS_DIR/client.crt" -days 365 -sha256

echo "Convertendo para Base64 e injetando no $ENV_FILE..."

# Compatível com linux e mac (ignorando novas linhas de forma segura)
b64_ca=$(cat "$CERTS_DIR/ca.crt" | base64 | tr -d '\n\r')
b64_server_crt=$(cat "$CERTS_DIR/server.crt" | base64 | tr -d '\n\r')
b64_server_key=$(cat "$CERTS_DIR/server.key" | base64 | tr -d '\n\r')
b64_client_crt=$(cat "$CERTS_DIR/client.crt" | base64 | tr -d '\n\r')
b64_client_key=$(cat "$CERTS_DIR/client.key" | base64 | tr -d '\n\r')

touch "$ENV_FILE"

# Remove old variables if present
for var in CA_CERT_B64 SERVER_CERT_B64 SERVER_KEY_B64 CLIENT_CERT_B64 CLIENT_KEY_B64; do
    sed -i -e "/^$var=/d" "$ENV_FILE" 2>/dev/null || sed -i "" -e "/^$var=/d" "$ENV_FILE" 2>/dev/null || true
done

echo "CA_CERT_B64=$b64_ca" >> "$ENV_FILE"
echo "SERVER_CERT_B64=$b64_server_crt" >> "$ENV_FILE"
echo "SERVER_KEY_B64=$b64_server_key" >> "$ENV_FILE"
echo "CLIENT_CERT_B64=$b64_client_crt" >> "$ENV_FILE"
echo "CLIENT_KEY_B64=$b64_client_key" >> "$ENV_FILE"

echo "Certificados gerados e gravados em $ENV_FILE com sucesso!"
