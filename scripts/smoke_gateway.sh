#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${PORT:-18080}"
BASE_URL="http://127.0.0.1:${PORT}"
ENTRYPOINT="${ROOT_DIR}/services/gateway/dist/index.js"
TMP_DIR="$(mktemp -d /tmp/gateway-smoke.XXXXXX)"

cleanup() {
  if [[ -n "${SERVER_PID:-}" ]]; then
    kill "${SERVER_PID}" >/dev/null 2>&1 || true
    wait "${SERVER_PID}" 2>/dev/null || true
  fi
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

if [[ ! -f "${ENTRYPOINT}" ]]; then
  echo "missing build output: ${ENTRYPOINT}"
  exit 1
fi

PORT="${PORT}" node "${ENTRYPOINT}" >"${TMP_DIR}/gateway.log" 2>&1 &
SERVER_PID=$!

for _ in {1..60}; do
  if ! kill -0 "${SERVER_PID}" >/dev/null 2>&1; then
    echo "gateway process exited during startup"
    cat "${TMP_DIR}/gateway.log"
    exit 1
  fi
  if curl -sS "${BASE_URL}/health" >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done

HEALTH_CODE="$(curl -sS -o "${TMP_DIR}/health.json" -w "%{http_code}" "${BASE_URL}/health")"
[[ "${HEALTH_CODE}" == "200" ]] || { echo "GET /health failed: ${HEALTH_CODE}"; cat "${TMP_DIR}/health.json"; exit 1; }

CHAT_CODE="$(curl -sS -o "${TMP_DIR}/chat.json" -w "%{http_code}" \
  -H "Content-Type: application/json" \
  -d '{"message":"hello"}' \
  "${BASE_URL}/chat")"
[[ "${CHAT_CODE}" == "200" ]] || { echo "POST /chat failed: ${CHAT_CODE}"; cat "${TMP_DIR}/chat.json"; exit 1; }

PLAN_CODE="$(curl -sS -o "${TMP_DIR}/plan.json" -w "%{http_code}" \
  -H "Content-Type: application/json" \
  -d '{"pet_id":"pet_smoke","species":"dog","weight_kg":10,"bucket":"IDEAL","activity":"MODERATE","goal":"MAINTAIN","food":{"kcal_per_g":3.5}}' \
  "${BASE_URL}/plan")"
[[ "${PLAN_CODE}" == "200" ]] || { echo "POST /plan failed: ${PLAN_CODE}"; cat "${TMP_DIR}/plan.json"; exit 1; }

BASE64_CMD="base64 --decode"
if ! echo "dGVzdA==" | base64 --decode >/dev/null 2>&1; then
  BASE64_CMD="base64 -D"
fi

printf '/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAMCAgICAgMCAgIDAwMDBAYEBAQEBAgGBgUGCQgKCgkICQkKDA8MCgsOCwkJDRENDg8QEBEQCgwSExIQEw8QEBD/2wBDAQMDAwQDBAgEBAgQCQgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgI/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAf/xAAVEAEBAAAAAAAAAAAAAAAAAAAAAf/aAAwDAQACEAMQAAAB2gD/xAAVEAEBAAAAAAAAAAAAAAAAAAAAEf/aAAgBAQABBQKf/8QAFBEBAAAAAAAAAAAAAAAAAAAAEP/aAAgBAwEBPwEf/8QAFBEBAAAAAAAAAAAAAAAAAAAAEP/aAAgBAgEBPwEf/8QAFBABAAAAAAAAAAAAAAAAAAAAEP/aAAgBAQAGPwJf/8QAFBABAAAAAAAAAAAAAAAAAAAAEP/aAAgBAQABPyFf/9k=' | $BASE64_CMD > "${TMP_DIR}/smoke.jpg"

ASSESS_CODE="$(curl -sS -o "${TMP_DIR}/assess.json" -w "%{http_code}" \
  -X POST "${BASE_URL}/assess" \
  -F "image=@${TMP_DIR}/smoke.jpg;type=image/jpeg" \
  -F 'request={"pet_id":"pet_smoke","species":"dog"}')"
if [[ "${ASSESS_CODE}" != "200" && "${ASSESS_CODE}" != "502" && "${ASSESS_CODE}" != "504" ]]; then
  echo "POST /assess expected 200/502/504, got ${ASSESS_CODE}"
  cat "${TMP_DIR}/assess.json"
  exit 1
fi

INVALID_HEADERS_FILE="${TMP_DIR}/invalid-headers.txt"
INVALID_CODE="$(curl -sS -D "${INVALID_HEADERS_FILE}" -o "${TMP_DIR}/invalid.json" -w "%{http_code}" \
  -H "Content-Type: application/json" \
  -d '{"image_url":"not-a-uri"}' \
  "${BASE_URL}/assess")"
[[ "${INVALID_CODE}" == "400" ]] || { echo "invalid payload expected 400, got ${INVALID_CODE}"; cat "${TMP_DIR}/invalid.json"; exit 1; }
grep -qi "^content-type: application/json" "${INVALID_HEADERS_FILE}" || {
  echo "invalid payload response was not JSON"
  exit 1
}

echo "gateway smoke passed"
