# ENV & Konfiguration (PowerShell Beispiele)

## Backend (Docker / API)
Diese Variablen werden über `infra/.env` oder `infra/.env.example` geladen (Docker Compose liest beide).

**Pflicht (für Auth/Multitenant):**
- `SITE_KEYS_JSON` – JSON-Map von Site-Key → Tenant-ID.
- `ADMIN_KEYS_JSON` – JSON-Map von Admin-Key → Tenant-ID.
- `JWT_SECRET` – JWT-Secret (fallback im Code ist `dev-secret-change-me`, aber für lokale Tests empfohlen).

**Datenbank (Standardwerte):**
- `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
- `DATABASE_URL` (optional, fallback auf Postgres-Default in Compose)

**Beispiel (`infra/.env`)**
```dotenv
SITE_KEYS_JSON={"HD-2026-9f3c1a2b-KEY":"hilders"}
ADMIN_KEYS_JSON={"HD-ADMIN-TEST-KEY":"hilders"}
JWT_SECRET=dev-secret-change-me
POSTGRES_USER=gemeinde
POSTGRES_PASSWORD=gemeinde
POSTGRES_DB=gemeinde
```

**PowerShell: Env-Variablen für Scripts setzen**
```powershell
$env:BASE_URL = "http://localhost:3000"
$env:TENANT = "hilders"
$env:SITE_KEY = "HD-2026-9f3c1a2b-KEY"
$env:ADMIN_KEY = "HD-ADMIN-TEST-KEY"
$env:JWT_SECRET = "dev-secret-change-me"
```

---

## Web-Admin (Next.js)
**Optional (Defaults im UI, aber vordefinierbar):**
- `NEXT_PUBLIC_API_BASE_URL` – z. B. `http://localhost:3000`
- `NEXT_PUBLIC_DEFAULT_TENANT` – z. B. `hilders`
- `NEXT_PUBLIC_DEFAULT_SITE_KEY`

**Beispiel (`apps/web-admin/.env.local`)**
```dotenv
NEXT_PUBLIC_API_BASE_URL=http://localhost:3000
NEXT_PUBLIC_DEFAULT_TENANT=hilders
NEXT_PUBLIC_DEFAULT_SITE_KEY=HD-2026-9f3c1a2b-KEY
```

**PowerShell (lokal, einmalig):**
```powershell
Copy-Item apps\web-admin\.env.example apps\web-admin\.env.local -Force
```

---

## Mobile (Flutter)
**Dart-Defines (Build-Time):**
- `DEMO_MODE=true` – Demo-Tenant + Demo-Site-Key + Android Emulator Base URL.
- `SITE_KEY=<site-key>` – überschreibt den Site-Key in Nicht-Demo-Modus.

**PowerShell Beispiel**
```powershell
Set-Location apps\mobile
flutter run --dart-define=DEMO_MODE=true
```
```powershell
flutter run --dart-define=SITE_KEY=HD-2026-9f3c1a2b-KEY
```
