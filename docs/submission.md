# Submission Notes

## What Is Complete
- Gateway now builds cleanly with installed `mongoose` and `@aws-sdk/client-s3`.
- Gateway/runtime config is aligned to local defaults:
  - ML: `http://127.0.0.1:8000`
  - Gateway: `http://127.0.0.1:8080`
- Smoke scripts are functional and non-empty:
  - `scripts/smoke_ml.sh`
  - `scripts/smoke_gateway.sh`
  - `scripts/smoke_e2e.sh`
- Gateway middleware/client scaffolding has concrete implementations:
  - `services/gateway/src/middleware/auth.ts`
  - `services/gateway/src/middleware/ratelimit.ts`
  - `services/gateway/src/clients/ml.ts`
  - `services/gateway/src/clients/featherless.ts`
- iOS app integration now uses backend auth + photos APIs (not mock-only).
- `packages/shared` now contains typed schema/type scaffolding instead of empty placeholders.
- ML core config/logging modules are implemented and wired to app startup.

## Known Runtime Dependencies
- MongoDB for gateway data persistence (`MONGODB_URI`)
- AWS S3 credentials for photo upload
- Featherless API key for best chat/vision model responses

## Quick Verify
1. Start ML service on `127.0.0.1:8000`.
2. Start gateway on `127.0.0.1:8080`.
3. Run `scripts/smoke_e2e.sh`.
4. Launch iOS app and verify:
   - Register/login hits gateway
   - Photos load/upload hits gateway
   - Chat returns assistant responses
