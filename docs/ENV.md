# ENV & Konfiguration

> **Warnung:** Fehlende Header (`X-TENANT`, `X-SITE-KEY`, optional `X-ADMIN-KEY`) führen zu **403/404**.

## Pflicht-Variablen (Backend)
Diese Variablen werden über `infra/.env` oder `infra/.env.example` geladen (Docker Compose liest beide).
- `SITE_KEYS_JSON` – JSON-Map von Site-Key → Tenant-ID (erforderlich für `X-SITE-KEY`).
- `JWT_SECRET` – JWT-Secret (Fallback im Code ist `dev-secret-change-me`, aber für lokale Tests empfohlen).

**Datenbank (Standardwerte):**
- `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
- `DATABASE_URL` (optional, Fallback auf Postgres-Default in Compose)

**Beispiel (`infra/.env`)**
```dotenv
SITE_KEYS_JSON={"HD-2026-9f3c1a2b-KEY":"hilders-demo"}
ADMIN_KEYS_JSON={"HD-ADMIN-TEST-KEY":"hilders-demo"}
JWT_SECRET=dev-secret-change-me
POSTGRES_USER=gemeinde
POSTGRES_PASSWORD=gemeinde
POSTGRES_DB=gemeinde
```

## Admin-only
- `ADMIN_KEYS_JSON` – JSON-Map von Admin-Key → Tenant-ID (erforderlich für `X-ADMIN-KEY`).
- Header: `X-ADMIN-KEY` ist für alle `/api/admin/*` Endpunkte Pflicht.

## Demo-only (hilders-demo)
- Mobile: `DEMO_MODE=true` aktiviert Demo-Tenant + Demo-Site-Key.
- API: Demo-Reset ist über `/api/admin/demo/reset` möglich (nur `hilders-demo`).

## Web-Admin (optional)
Diese Variablen setzen Defaults im UI:
- `NEXT_PUBLIC_API_BASE_URL` – z. B. `http://localhost:3000`
- `NEXT_PUBLIC_DEFAULT_TENANT` – z. B. `hilders-demo`
- `NEXT_PUBLIC_DEFAULT_SITE_KEY`

**Beispiel (`apps/web-admin/.env.local`)**
```dotenv
NEXT_PUBLIC_API_BASE_URL=http://localhost:3000
NEXT_PUBLIC_DEFAULT_TENANT=hilders-demo
NEXT_PUBLIC_DEFAULT_SITE_KEY=HD-2026-9f3c1a2b-KEY
```

## PowerShell (kanonisches Beispiel)
```powershell
$env:BASE_URL = "http://localhost:3000"
$env:TENANT = "hilders-demo"
$env:SITE_KEY = "HD-2026-9f3c1a2b-KEY"
$env:ADMIN_KEY = "HD-ADMIN-TEST-KEY"
$env:JWT_SECRET = "dev-secret-change-me"
```

## Mobile (Flutter)
- Demo-Mode: `flutter run --dart-define=DEMO_MODE=true`
- Site-Key override: `flutter run --dart-define=SITE_KEY=HD-2026-9f3c1a2b-KEY`
