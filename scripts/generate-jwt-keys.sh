#!/usr/bin/env bash
set -e

KEYS_DIR="infra/docker/certs"
ENV_FILE="infra/docker/.env"

mkdir -p "$KEYS_DIR"

echo "Gerando par de chaves RSA (2048-bit) para assinatura de JWT (RS256)..."
openssl genrsa -out "$KEYS_DIR/jwt_private.pem" 2048
openssl rsa -in "$KEYS_DIR/jwt_private.pem" -pubout -out "$KEYS_DIR/jwt_public.pem"

b64_pub=$(cat "$KEYS_DIR/jwt_public.pem" | base64 | tr -d '\n\r')

touch "$ENV_FILE"

# Remove variáveis antigas se existirem
sed -i -e "/^JWT_PUBLIC_KEY_B64=/d" "$ENV_FILE" 2>/dev/null || sed -i "" -e "/^JWT_PUBLIC_KEY_B64=/d" "$ENV_FILE" 2>/dev/null || true
sed -i -e "/^JWT_SECRET=/d" "$ENV_FILE" 2>/dev/null || sed -i "" -e "/^JWT_SECRET=/d" "$ENV_FILE" 2>/dev/null || true

echo "JWT_PUBLIC_KEY_B64=$b64_pub" >> "$ENV_FILE"

echo "Chaves JWT geradas com sucesso!"
echo "Privada (IdP / Emissor): $KEYS_DIR/jwt_private.pem"
echo "Pública (API Resource Server): $KEYS_DIR/jwt_public.pem"
echo "JWT_PUBLIC_KEY_B64 injetada em $ENV_FILE"
