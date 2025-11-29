#!/usr/bin/env bash
# Run a synthetic load test against the Rootly WAF using wrk and collect logs/metrics.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
RESULTS_DIR="${PROJECT_DIR}/loadtest-results"
CERT_PATH="${PROJECT_DIR}/waf-ca.pem"
RUN_ID="$(date -u +"%Y%m%dT%H%M%SZ")"
RUN_DIR="${RESULTS_DIR}/${RUN_ID}"

ENDPOINT="/api/v1/plants"
THREADS=4
CONNECTIONS=40
DURATION="30s"
TIMEOUT="10s"
HOST_HEADER="localhost"
ACCEPT_HEADER="application/json"
TOKEN=""
TOKEN_FILE=""
TAIL_LINES=200
WAF_SERVICE="rootly-waf"
NETWORK_NAME="rootly-public-network"
WRK_IMAGE="${WRK_IMAGE:-williamyeh/wrk:latest}"
SKIP_CERT="false"
LOG_ONLY="false"
SKIP_LOGS="false"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --endpoint <path>          Ruta relativa a probar (default: ${ENDPOINT})
  --threads <N>              Número de hilos para wrk (default: ${THREADS})
  --connections <N>          Conexiones concurrentes (default: ${CONNECTIONS})
  --duration <T>             Duración de la prueba (default: ${DURATION})
  --timeout <T>              Timeout de wrk (default: ${TIMEOUT})
  --host-header <value>      Valor para cabecera Host (default: ${HOST_HEADER})
  --accept <value>           Cabecera Accept (default: ${ACCEPT_HEADER})
  --token <jwt>              Token Bearer a inyectar
  --token-file <path>        Archivo que contiene el token (se ignora --token si se usa)
  --tail-lines <N>           Líneas a capturar de cada log (default: ${TAIL_LINES})
  --network <name>           Red Docker para el contenedor de pruebas (default: ${NETWORK_NAME})
  --skip-cert-copy           No copiar el certificado del WAF (usar archivo existente)
  --log-only                 Saltar ejecución de wrk y solo recolectar logs
  --skip-logs                No recolectar logs al finalizar la prueba
  -h, --help                 Mostrar esta ayuda

Los artefactos quedarán en: ${RESULTS_DIR}/<timestamp>/
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --endpoint)
      ENDPOINT="$2"; shift 2;;
    --threads)
      THREADS="$2"; shift 2;;
    --connections)
      CONNECTIONS="$2"; shift 2;;
    --duration)
      DURATION="$2"; shift 2;;
    --timeout)
      TIMEOUT="$2"; shift 2;;
    --host-header)
      HOST_HEADER="$2"; shift 2;;
    --accept)
      ACCEPT_HEADER="$2"; shift 2;;
    --token)
      TOKEN="$2"; shift 2;;
    --token-file)
      TOKEN_FILE="$2"; shift 2;;
    --tail-lines)
      TAIL_LINES="$2"; shift 2;;
    --network)
      NETWORK_NAME="$2"; shift 2;;
    --skip-cert-copy)
      SKIP_CERT="true"; shift;;
    --log-only)
      LOG_ONLY="true"; shift;;
    --skip-logs)
      SKIP_LOGS="true"; shift;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Opción desconocida: $1" >&2
      usage
      exit 1;;
  esac
done

if [[ -n "${TOKEN_FILE}" ]]; then
  if [[ ! -f "${TOKEN_FILE}" ]]; then
    echo "El archivo de token no existe: ${TOKEN_FILE}" >&2
    exit 1
  fi
  TOKEN="$(<"${TOKEN_FILE}")"
fi

mkdir -p "${RUN_DIR}"

if [[ "${LOG_ONLY}" != "true" ]]; then
  echo "[INFO] Ejecutando prueba con wrk..."
  if [[ "${SKIP_CERT}" != "true" ]]; then
    if ! docker cp "${WAF_SERVICE}:/etc/nginx/certs/fullchain.pem" "${CERT_PATH}" >/dev/null 2>&1; then
      echo "No fue posible copiar el certificado desde ${WAF_SERVICE}. ¿Está el contenedor en ejecución?" >&2
      exit 1
    fi
  fi

  WRK_HEADERS=("Host: ${HOST_HEADER}" "Accept: ${ACCEPT_HEADER}")
  if [[ -n "${TOKEN}" ]]; then
    WRK_HEADERS+=("Authorization: Bearer ${TOKEN}")
  fi

  CLIENT_SCRIPT="${RUN_DIR}/run-wrk.sh"
  {
    echo "#!/bin/sh"
    echo "set -e"
    echo "if command -v update-ca-certificates >/dev/null 2>&1; then"
    echo "  update-ca-certificates >/dev/null 2>&1 || true"
    echo "fi"
    printf "exec wrk"
    printf " %s" "-t${THREADS}" "-c${CONNECTIONS}" "-d${DURATION}" "--latency" "--timeout" "${TIMEOUT}"
    for header in "${WRK_HEADERS[@]}"; do
      printf " %s %s" "-H" "$(printf '%q' "${header}")"
    done
    printf " %s" "$(printf '%q' "https://rootly-waf${ENDPOINT}")"
    echo
  } > "${CLIENT_SCRIPT}"
  chmod +x "${CLIENT_SCRIPT}"

  if ! docker run --rm --network "${NETWORK_NAME}" \
    --entrypoint /bin/sh \
    -v "${CERT_PATH}:/usr/local/share/ca-certificates/waf-ca.crt:ro" \
    -v "${CLIENT_SCRIPT}:/tmp/run-wrk.sh:ro" \
    "${WRK_IMAGE}" -c "/tmp/run-wrk.sh" | tee "${RUN_DIR}/wrk.txt"
  then
    echo "La ejecución de wrk falló." >&2
    exit 1
  fi
else
  echo "[INFO] Modo log-only: se omite la ejecución de wrk."
fi

if [[ "${SKIP_LOGS}" != "true" ]]; then
  echo "[INFO] Extrayendo logs del WAF..."
  docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec "${WAF_SERVICE}" sh -c "tail -n ${TAIL_LINES} /var/log/nginx/access.log" > "${RUN_DIR}/nginx-access.log" || true
  docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec "${WAF_SERVICE}" sh -c "tail -n ${TAIL_LINES} /var/log/nginx/error.log" > "${RUN_DIR}/nginx-error.log" || true
  docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec "${WAF_SERVICE}" sh -c "tail -n ${TAIL_LINES} /var/log/modsecurity/audit.log" > "${RUN_DIR}/modsecurity-audit.log" || true
else
  echo "[INFO] Omitiendo recolección de logs por solicitud (--skip-logs)."
fi

cat <<EOF > "${RUN_DIR}/metadata.json"
{
  "run_id": "${RUN_ID}",
  "endpoint": "${ENDPOINT}",
  "threads": ${THREADS},
  "connections": ${CONNECTIONS},
  "duration": "${DURATION}",
  "timeout": "${TIMEOUT}",
  "host_header": "${HOST_HEADER}",
  "accept_header": "${ACCEPT_HEADER}",
  "token_supplied": $( [[ -n "${TOKEN}" ]] && echo "true" || echo "false" ),
  "network": "${NETWORK_NAME}",
  "wrk_image": "${WRK_IMAGE}"
}
EOF

if [[ "${SKIP_LOGS}" != "true" ]]; then
  echo "[INFO] Generando métricas..."
  python3 <<'PY' "${RUN_DIR}"
import json
import re
import sys
from collections import Counter
from pathlib import Path

run_dir = Path(sys.argv[1])
summary = {
    "wrk": {},
    "nginx": {"status_counts": {}, "total_entries": 0},
    "modsecurity": {"rule_hits": {}, "total_entries": 0},
}

wrk_path = run_dir / "wrk.txt"
if wrk_path.exists():
    text = wrk_path.read_text()
    total_req = re.search(r"(\d+)\s+requests in\s+([\d\.]+)s", text)
    req_per_sec = re.search(r"Requests/sec:\s+([\d\.]+)", text)
    non_2xx = re.search(r"Non-2xx or 3xx responses:\s+(\d+)", text)
    if total_req:
        summary["wrk"]["requests_total"] = int(total_req.group(1))
        summary["wrk"]["reported_duration_seconds"] = float(total_req.group(2))
    if req_per_sec:
        summary["wrk"]["requests_per_second"] = float(req_per_sec.group(1))
    if non_2xx:
        summary["wrk"]["non_2xx_3xx"] = int(non_2xx.group(1))

access_path = run_dir / "nginx-access.log"
if access_path.exists():
    statuses = Counter()
    for line in access_path.read_text().splitlines():
        parts = line.split()
        if len(parts) >= 9 and parts[8].isdigit():
            statuses[parts[8]] += 1
    summary["nginx"]["status_counts"] = dict(statuses)
    summary["nginx"]["total_entries"] = sum(statuses.values())

audit_path = run_dir / "modsecurity-audit.log"
if audit_path.exists():
    rule_hits = Counter()
    for line in audit_path.read_text().splitlines():
        for pattern in (r'Rule Id: (\d+)', r'ruleId "?(\d+)"?'):
            match = re.search(pattern, line)
            if match:
                rule_hits[match.group(1)] += 1
    summary["modsecurity"]["rule_hits"] = dict(rule_hits)
    summary["modsecurity"]["total_entries"] = sum(rule_hits.values())

summary_path = run_dir / "summary.json"
summary_path.write_text(json.dumps(summary, indent=2))
PY
else
  echo "[INFO] No se generarán métricas porque se omitieron los logs."
fi

echo "[INFO] Artefactos guardados en ${RUN_DIR}"

