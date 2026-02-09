# PocketPaws TidalHack26

PocketPaws is a pet wellness prototype with:
- `services/ml`: FastAPI ML service (`/health`, `/assess`, `/plan`, `/chat`)
- `services/gateway`: TypeScript API gateway (`/auth`, `/diary`, `/photos`, `/assess`, `/plan`, `/chat`)
- `apps`: React web client
- `PocketPaws`: SwiftUI iOS client

## Local Ports
- ML service: `8000`
- Gateway: `8080`
- Web app (Vite): `5173`

The gateway reads `PORT` first and falls back to `GATEWAY_PORT` for backward compatibility.

## Environment
1. Copy `.env.example` to `.env` and fill required values.
2. Required for full photo upload flow:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `S3_BUCKET`
- `S3_REGION`
3. Required for production-quality model responses:
- `FEATHERLESS_API_KEY`
- `FEATHERLESS_SECRET_KEY`

## Run Gateway
```bash
npm --prefix services/gateway install
npm --prefix services/gateway run build
PORT=8080 npm --prefix services/gateway run dev
```

## Run ML Service
```bash
cd services/ml
python3 -m venv .venv
source .venv/bin/activate
pip install -e '.[dev]'
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

## Smoke Tests
- ML-only smoke:
```bash
scripts/smoke_ml.sh
```
- Gateway smoke (expects built gateway):
```bash
npm --prefix services/gateway run build
scripts/smoke_gateway.sh
```
- Combined smoke:
```bash
scripts/smoke_e2e.sh
```

## iOS Integration Notes
The iOS app now calls gateway APIs for:
- `POST /auth/login`
- `POST /auth/register`
- `GET /photos`
- `POST /photos/upload`
- `POST /chat`

`PocketPaws/Info.plist` controls base URL via `GATEWAY_BASE_URL`.

## Contract Docs
- Canonical API contract: `docs/api.md`
- Submission checklist/context: `docs/submission.md`
