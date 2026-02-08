#!/usr/bin/env bash
set -euo pipefail

GATEWAY_URL="${GATEWAY_URL:-http://127.0.0.1:3000}"
ML_URL="${ML_URL:-http://127.0.0.1:8000}"
IMAGE_PATH="${1:-${IMAGE_PATH:-}}"

TMP_DIR="$(mktemp -d /tmp/tidal-smoke.XXXXXX)"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
}

compact_json() {
  tr -d '\n\r\t ' < "$1"
}

print_body() {
  local file="$1"
  if command -v jq >/dev/null 2>&1; then
    jq . "$file" || cat "$file"
  else
    cat "$file"
  fi
}

assert_error_shape() {
  local file="$1"
  local compact
  compact="$(compact_json "$file")"
  if [[ "$compact" != *'"error":{"code":'* ]] || [[ "$compact" != *'"message":'* ]] || [[ "$compact" != *'"retryable":'* ]]; then
    echo "error shape mismatch in response:"
    print_body "$file"
    exit 1
  fi
}

run_json() {
  local name="$1"
  local expected="$2"
  local method="$3"
  local url="$4"
  local payload="${5:-}"
  local out="${TMP_DIR}/${name}.json"

  local code
  if [[ -n "$payload" ]]; then
    code="$(curl -sS -o "$out" -w "%{http_code}" -X "$method" "$url" \
      -H "Content-Type: application/json" \
      -d "$payload")"
  else
    code="$(curl -sS -o "$out" -w "%{http_code}" -X "$method" "$url")"
  fi

  if [[ "$code" != "$expected" ]]; then
    echo "[FAIL] ${name}: expected ${expected}, got ${code}"
    print_body "$out"
    exit 1
  fi

  echo "[PASS] ${name} (${code})"
}

need_cmd curl

echo "Using gateway: ${GATEWAY_URL}"
echo "Using ml:      ${ML_URL}"
echo

run_json "ml_health" "200" "GET" "${ML_URL}/health"
run_json "gw_health" "200" "GET" "${GATEWAY_URL}/health"

run_json "gw_chat" "200" "POST" "${GATEWAY_URL}/chat" \
  '{"message":"My dog is low energy today. What should I do?"}'

run_json "gw_plan" "200" "POST" "${GATEWAY_URL}/plan" \
  '{"pet_id":"pet_123","species":"dog","weight_kg":10.0,"bucket":"IDEAL","activity":"MODERATE","goal":"MAINTAIN","food":{"kcal_per_g":3.5}}'

run_json "gw_plan_invalid" "400" "POST" "${GATEWAY_URL}/plan" '{}'
assert_error_shape "${TMP_DIR}/gw_plan_invalid.json"
echo "[PASS] gw_plan_invalid error shape"

if [[ -n "${IMAGE_PATH}" ]]; then
  if [[ ! -f "${IMAGE_PATH}" ]]; then
    echo "image not found: ${IMAGE_PATH}" >&2
    exit 1
  fi
  ASSESS_OUT="${TMP_DIR}/gw_assess.json"
  ASSESS_CODE="$(curl -sS -o "${ASSESS_OUT}" -w "%{http_code}" \
    -X POST "${GATEWAY_URL}/assess" \
    -F "image=@${IMAGE_PATH}" \
    -F 'request={"pet_id":"pet_123","species":"dog","breed_hint":"labrador"}')"
  if [[ "${ASSESS_CODE}" != "200" ]]; then
    echo "[FAIL] gw_assess: expected 200, got ${ASSESS_CODE}"
    print_body "${ASSESS_OUT}"
    exit 1
  fi
  echo "[PASS] gw_assess (${ASSESS_CODE})"
else
  echo "[SKIP] gw_assess (no image provided)"
  echo "       run: scripts/smoke.sh /absolute/path/to/image.jpg"
fi

echo
echo "Smoke checks passed."
