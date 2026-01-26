# COMMAND CHEATSHEET (PowerShell)

> Alle Pfade sind Windows-freundlich. Führe Befehle aus dem Repo-Root aus.

## Alles starten (Kurzfassung)
1. **Backend (Docker Compose)**
   ```powershell
   Set-Location infra
   Copy-Item .env.example .env -Force
   docker compose up -d --build
   Set-Location ..
   ```
2. **Web-Admin (Next.js, Port 3001)**
   ```powershell
   npm --prefix apps/web-admin install
   npm --prefix apps/web-admin run dev -p 3001
   ```
3. **Mobile (Flutter)**
   ```powershell
   Set-Location apps\mobile
   flutter pub get
   flutter run
   ```

---

## Backend (Docker)
**Starten**
```powershell
Set-Location infra
Copy-Item .env.example .env -Force
docker compose up -d --build
```

**Stoppen**
```powershell
docker compose down
```

**Logs ansehen**
```powershell
docker compose logs -f api
```

**Healthcheck**
```powershell
Invoke-RestMethod http://localhost:3000/health
```

---

## Web-Admin (Next.js)
```powershell
npm --prefix apps/web-admin install
npm --prefix apps/web-admin run dev -p 3001
```
Öffnen: `http://localhost:3001`

---

## Mobile (Flutter)
```powershell
Set-Location apps\mobile
flutter pub get
flutter run
```

**Demo-Mode**
```powershell
flutter run --dart-define=DEMO_MODE=true
```

**Optional: SITE_KEY setzen (Prod/Dev-Tenant)**
```powershell
flutter run --dart-define=SITE_KEY=HD-2026-9f3c1a2b-KEY
```

---

## Seed-Skripte (API)
```powershell
npm --prefix apps/api run seed:tenant -- <tenantId>
npm --prefix apps/api run seed:hilders
npm --prefix apps/api run seed:hilders-demo
npm --prefix apps/api run seed:tourism:hilders
```

---

## Wichtige API-Calls (PowerShell, Copy/Paste)
> Hinweis: Für **Admin-Endpunkte** sind `X-TENANT`, `X-SITE-KEY`, `X-ADMIN-KEY` erforderlich.

### 1) Resident anlegen (Admin)
```powershell
$headers = @{
  "Content-Type" = "application/json"
  "X-TENANT" = "hilders"
  "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
  "X-ADMIN-KEY" = "HD-ADMIN-TEST-KEY"
}
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/admin/residents" `
  -Headers $headers `
  -Body '{"firstName":"Anna","lastName":"Muster","postalCode":"36115","houseNumber":"12A"}'
```

### 2) Activation-Code erzeugen (Admin)
```powershell
$headers = @{
  "Content-Type" = "application/json"
  "X-TENANT" = "hilders"
  "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
  "X-ADMIN-KEY" = "HD-ADMIN-TEST-KEY"
}
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/admin/activation-codes" `
  -Headers $headers `
  -Body '{"residentId":"<residentId>","expiresInDays":14}'
```

### 3) Resident aktivieren (User)
```powershell
$headers = @{
  "Content-Type" = "application/json"
  "X-TENANT" = "hilders"
  "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
}
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/auth/activate" `
  -Headers $headers `
  -Body '{"activationCode":"<code>","postalCode":"36115","houseNumber":"12A","email":"user@example.com","password":"Passwort123!"}'
```

### 4) Login (User)
```powershell
$headers = @{
  "Content-Type" = "application/json"
  "X-TENANT" = "hilders"
  "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
}
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/auth/login" `
  -Headers $headers `
  -Body '{"email":"user@example.com","password":"Passwort123!"}'
```

### 5) Permissions abrufen (User Token)
```powershell
$headers = @{
  "X-TENANT" = "hilders"
  "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
  "Authorization" = "Bearer <accessToken>"
}
Invoke-RestMethod -Method Get -Uri "http://localhost:3000/permissions" `
  -Headers $headers
```

### 6) Rolle setzen (Admin)
```powershell
$headers = @{
  "Content-Type" = "application/json"
  "X-TENANT" = "hilders"
  "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
  "X-ADMIN-KEY" = "HD-ADMIN-TEST-KEY"
}
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/admin/users/role" `
  -Headers $headers `
  -Body '{"userId":"<userId>","role":"STAFF"}'
```

### 7) Bürger-Post erstellen (Citizen)
```powershell
$headers = @{
  "Content-Type" = "application/json"
  "X-TENANT" = "hilders"
  "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
  "Authorization" = "Bearer <accessToken>"
}
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/posts" `
  -Headers $headers `
  -Body '{"type":"USER_POST","title":"Hallo Nachbarn","body":"Testpost"}'
```

### 8) Offiziellen Post erstellen (Admin, News/Warnung)
```powershell
$headers = @{
  "Content-Type" = "application/json"
  "X-TENANT" = "hilders"
  "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
  "X-ADMIN-KEY" = "HD-ADMIN-TEST-KEY"
}
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/admin/posts" `
  -Headers $headers `
  -Body '{"type":"NEWS","title":"Amtliche Info","body":"Inhalt","publishedAt":"2024-12-01T08:00:00.000Z"}'
```

### 9) Beitrag melden + Moderation abrufen
```powershell
# Report
$headers = @{
  "Content-Type" = "application/json"
  "X-TENANT" = "hilders"
  "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
  "Authorization" = "Bearer <accessToken>"
}
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/posts/<postId>/report" `
  -Headers $headers `
  -Body '{}'

# Moderation (Backend-Route)
$headers = @{
  "X-TENANT" = "hilders"
  "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
  "X-ADMIN-KEY" = "HD-ADMIN-TEST-KEY"
}
Invoke-RestMethod -Method Get -Uri "http://localhost:3000/admin/posts/reported" `
  -Headers $headers
```

### 10) Tourist-Code einlösen
```powershell
$headers = @{
  "Content-Type" = "application/json"
  "X-TENANT" = "hilders"
  "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
}
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/tourist/redeem" `
  -Headers $headers `
  -Body '{"code":"<touristCode>","deviceId":"device-123"}'
```

---

## Troubleshooting (Kurz)
- **Port belegt**: API nutzt `3000`, Web-Admin `3001`. Ändere den Port oder stoppe den Prozess.
- **403/401**: `X-TENANT`, `X-SITE-KEY`, `X-ADMIN-KEY` fehlen oder sind falsch.
- **404**: Route prüfen (z. B. Moderation ist `/admin/posts/...`, nicht `/api/admin/posts/...`).
- **Android Emulator**: API-Base-URL in der App ist `http://10.0.2.2:3000` (Debug/Demo).
