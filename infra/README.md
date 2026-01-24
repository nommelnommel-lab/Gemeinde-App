# Infra

## Environment setup

### Quick start

1. Copy the example env file:
   ```bash
   cp .env.example .env
   ```
2. Start the stack:
   ```bash
   docker compose up -d --build
   ```
3. Verify the admin keys are present:
   ```bash
   docker compose exec api printenv ADMIN_KEYS_JSON
   ```

### Notes

1. Copy the example env file:
   ```bash
   cp .env.example .env
   ```
   > Tipp: Ohne `.env` werden die Defaults aus `.env.example` geladen, aber wir empfehlen eine eigene `.env` für lokale Anpassungen.
2. After changing `.env`, restart the stack:
   ```bash
   docker compose down
   docker compose up -d --build
   ```

### Example values

```dotenv
SITE_KEYS_JSON={"HD-2026-9f3c1a2b-KEY":"hilders","NEW-2026-KEY":"new-town"}
ADMIN_KEYS_JSON={"ADMIN-KEY-1":"hilders","ADMIN-KEY-2":"new-town"}
JWT_SECRET=dev-secret-change-me
POSTGRES_USER=gemeinde
POSTGRES_PASSWORD=gemeinde
POSTGRES_DB=gemeinde
DATABASE_URL=postgresql://gemeinde:gemeinde@postgres:5432/gemeinde
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
