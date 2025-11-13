#!/usr/bin/env bash
# Generate self-signed certificates for reverse-proxy and frontend-ssr (development only)
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CERTS_DIR="${ROOT_DIR}/certs"

mkdir -p "${CERTS_DIR}/reverse-proxy" "${CERTS_DIR}/frontend"

generate_cert() {
  local name="$1"
  local key_path="$2"
  local cert_path="$3"
  local cn="$4"

  if [[ -f "${key_path}" && -f "${cert_path}" ]]; then
    echo "[INFO] Certificates for ${name} already exist. Skipping generation."
    return
  fi

  echo "[INFO] Generating self-signed certificate for ${name}..."
  openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout "${key_path}" \
    -out "${cert_path}" \
    -subj "/C=CO/ST=Bogota/L=Bogota/O=Rootly/OU=Dev/CN=${cn}" >/dev/null 2>&1
}

generate_cert "reverse-proxy" \
  "${CERTS_DIR}/reverse-proxy/privkey.pem" \
  "${CERTS_DIR}/reverse-proxy/fullchain.pem" \
  "reverse-proxy"

generate_cert "frontend-ssr" \
  "${CERTS_DIR}/frontend/frontend.key" \
  "${CERTS_DIR}/frontend/frontend.crt" \
  "frontend-ssr"

echo "[INFO] Certificates ready in ${CERTS_DIR}"

