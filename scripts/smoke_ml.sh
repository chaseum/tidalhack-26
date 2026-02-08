#!/usr/bin/env bash
set -euo pipefail

ML_URL="${ML_URL:-http://127.0.0.1:8000}"
TMP_DIR="$(mktemp -d /tmp/ml-smoke.XXXXXX)"

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

print_body() {
  local file="$1"
  if command -v jq >/dev/null 2>&1; then
    jq . "$file" || cat "$file"
  else
    cat "$file"
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

echo "Using ml: ${ML_URL}"
echo

run_json "health" "200" "GET" "${ML_URL}/health"
run_json "chat" "200" "POST" "${ML_URL}/chat" '{"message":"My dog is low energy today. What should I do?"}'
run_json "plan" "200" "POST" "${ML_URL}/plan" \
  '{"pet_id":"pet_123","species":"dog","weight_kg":10.0,"bucket":"IDEAL","activity":"MODERATE","goal":"MAINTAIN","food":{"kcal_per_g":3.5}}'

echo
echo "ML smoke checks passed."
