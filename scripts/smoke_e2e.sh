#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ML_URL="${ML_URL:-http://127.0.0.1:8000}"
GATEWAY_URL="${GATEWAY_URL:-http://127.0.0.1:8080}"

echo "Running ML smoke..."
ML_URL="${ML_URL}" "${ROOT_DIR}/scripts/smoke_ml.sh"
echo
echo "Building gateway..."
npm --prefix "${ROOT_DIR}/services/gateway" run build >/dev/null
echo "Gateway build complete."
echo
echo "Running gateway smoke..."
PORT="${PORT:-8080}" "${ROOT_DIR}/scripts/smoke_gateway.sh"
echo
echo "E2E smoke checks passed."
