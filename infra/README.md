# Infra

## Environment setup

1. Copy the example env file:
   ```bash
   cp .env.example .env
   ```
2. After changing `.env`, restart the stack:
   ```bash
   docker compose down
   docker compose up -d --build
   ```

## Windows (PowerShell) setup

1. Copy the example env file:
   ```powershell
   Copy-Item .env.example .env
   ```
2. Restart the stack after any `.env` changes:
   ```powershell
   docker compose down
   docker compose up -d --build
   ```
3. Verify the keys are available inside the container:
   ```powershell
   docker compose exec api printenv ADMIN_KEYS_JSON
   docker compose exec api printenv SITE_KEYS_JSON
   ```

Missing `ADMIN_KEYS_JSON` or `SITE_KEYS_JSON` will cause admin auth to return 401.

## Smoke check

```bash
curl http://localhost:3000/api/health
docker compose exec api printenv ADMIN_KEYS_JSON
docker compose exec api printenv SITE_KEYS_JSON
```
