#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${PORT:-18080}"
BASE_URL="http://127.0.0.1:${PORT}"
ENTRYPOINT="${ROOT_DIR}/services/gateway/dist/index.js"

cleanup() {
  if [[ -n "${SERVER_PID:-}" ]]; then
    kill "${SERVER_PID}" >/dev/null 2>&1 || true
    wait "${SERVER_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

if [[ ! -f "${ENTRYPOINT}" ]]; then
  echo "missing build output: ${ENTRYPOINT}"
  exit 1
fi

PORT="${PORT}" node "${ENTRYPOINT}" >/tmp/gateway-smoke.log 2>&1 &
SERVER_PID=$!

for _ in {1..40}; do
  if ! kill -0 "${SERVER_PID}" >/dev/null 2>&1; then
    echo "gateway process exited during startup"
    cat /tmp/gateway-smoke.log
    exit 1
  fi
  if curl -sS "${BASE_URL}/health" >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done

HEALTH_CODE="$(curl -sS -o /tmp/gateway-health.json -w "%{http_code}" "${BASE_URL}/health")"
[[ "${HEALTH_CODE}" == "200" ]] || { echo "GET /health failed: ${HEALTH_CODE}"; exit 1; }

ASSESS_CODE="$(curl -sS -o /tmp/gateway-assess.json -w "%{http_code}" \
  -H "Content-Type: application/json" \
  -d '{"image_url":"https://example.com/image1.jpg"}' \
  "${BASE_URL}/assess")"
[[ "${ASSESS_CODE}" == "200" ]] || { echo "POST /assess failed: ${ASSESS_CODE}"; exit 1; }

CHAT_CODE="$(curl -sS -o /tmp/gateway-chat.json -w "%{http_code}" \
  -H "Content-Type: application/json" \
  -d '{"message":"hello"}' \
  "${BASE_URL}/chat")"
[[ "${CHAT_CODE}" == "200" ]] || { echo "POST /chat failed: ${CHAT_CODE}"; exit 1; }

INVALID_HEADERS_FILE="/tmp/gateway-invalid-headers.txt"
INVALID_CODE="$(curl -sS -D "${INVALID_HEADERS_FILE}" -o /tmp/gateway-invalid.json -w "%{http_code}" \
  -H "Content-Type: application/json" \
  -d '{"image_url":"not-a-uri"}' \
  "${BASE_URL}/assess")"
[[ "${INVALID_CODE}" == "400" ]] || { echo "invalid payload expected 400, got ${INVALID_CODE}"; exit 1; }
grep -qi "^content-type: application/json" "${INVALID_HEADERS_FILE}" || {
  echo "invalid payload response was not JSON"
  exit 1
}

echo "gateway smoke passed"
