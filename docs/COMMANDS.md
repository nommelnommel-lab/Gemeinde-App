# COMMANDS (PowerShell)

> Alle Pfade sind Windows‑PowerShell‑kompatibel. Befehle werden aus dem Repo‑Root ausgeführt.

## Infrastructure / Backend

Starte Postgres + API via Docker Compose.
```powershell
Push-Location infra
Copy-Item .env.example .env -Force
docker compose up -d --build
Pop-Location
```

Stoppe die Container.
```powershell
Push-Location infra
docker compose down
Pop-Location
```

Zeige API‑Logs im Follow‑Modus.
```powershell
Push-Location infra
docker compose logs -f api
Pop-Location
```

## Web‑Admin

Installiere Abhängigkeiten und starte den Dev‑Server auf Port 3001.
```powershell
npm --prefix apps/web-admin install
npm --prefix apps/web-admin run dev -p 3001
```

## Mobile App

Installiere Abhängigkeiten und starte die App.
```powershell
Set-Location apps\mobile
flutter pub get
flutter run
```

Starte die Mobile‑App im Demo‑Mode.
```powershell
Set-Location apps\mobile
flutter run --dart-define=DEMO_MODE=true
```

Setze optional den Site‑Key (Nicht‑Demo‑Modus).
```powershell
Set-Location apps\mobile
flutter run --dart-define=SITE_KEY=HD-2026-9f3c1a2b-KEY
```

## Demo & Seed

Seed‑Daten für Tenants und Demo‑Inhalte (optional nach Bedarf).
```powershell
npm --prefix apps/api run seed:tenant -- <tenantId>
npm --prefix apps/api run seed:hilders
npm --prefix apps/api run seed:hilders-demo
npm --prefix apps/api run seed:tourism:hilders
npm --prefix apps/api run seed:demo
```

## Testing & Debugging

Führe einen Health‑Check der API aus.
```powershell
Invoke-RestMethod http://localhost:3000/health
```

> Hinweis: Für **Admin‑Endpunkte** sind `X-TENANT`, `X-SITE-KEY`, `X-ADMIN-KEY` erforderlich.

Lege einen Resident als Admin an.
```powershell
$headers = @{
  "Content-Type" = "application/json"
  "X-TENANT" = "hilders-demo"
  "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
  "X-ADMIN-KEY" = "HD-ADMIN-TEST-KEY"
}
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/admin/residents" `
  -Headers $headers `
  -Body '{"firstName":"Anna","lastName":"Muster","postalCode":"36115","houseNumber":"12A"}'
```

Erzeuge einen Activation‑Code (Admin).
```powershell
$headers = @{
  "Content-Type" = "application/json"
  "X-TENANT" = "hilders-demo"
  "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
  "X-ADMIN-KEY" = "HD-ADMIN-TEST-KEY"
}
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/admin/activation-codes" `
  -Headers $headers `
  -Body '{"residentId":"<residentId>","expiresInDays":14}'
```

Aktiviere einen Resident (User).
```powershell
$headers = @{
  "Content-Type" = "application/json"
  "X-TENANT" = "hilders-demo"
  "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
}
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/auth/activate" `
  -Headers $headers `
  -Body '{"activationCode":"<code>","postalCode":"36115","houseNumber":"12A","email":"user@example.com","password":"Passwort123!"}'
```

Login als User.
```powershell
$headers = @{
  "Content-Type" = "application/json"
  "X-TENANT" = "hilders-demo"
  "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
}
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/auth/login" `
  -Headers $headers `
  -Body '{"email":"user@example.com","password":"Passwort123!"}'
```

Lese Berechtigungen mit User‑Token aus.
```powershell
$headers = @{
  "X-TENANT" = "hilders-demo"
  "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
  "Authorization" = "Bearer <accessToken>"
}
Invoke-RestMethod -Method Get -Uri "http://localhost:3000/permissions" `
  -Headers $headers
```

Setze eine Rolle (Admin).
```powershell
$headers = @{
  "Content-Type" = "application/json"
  "X-TENANT" = "hilders-demo"
  "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
  "X-ADMIN-KEY" = "HD-ADMIN-TEST-KEY"
}
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/admin/users/role" `
  -Headers $headers `
  -Body '{"userId":"<userId>","role":"STAFF"}'
```

Erstelle einen Bürger‑Post (Citizen).
```powershell
$headers = @{
  "Content-Type" = "application/json"
  "X-TENANT" = "hilders-demo"
  "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
  "Authorization" = "Bearer <accessToken>"
}
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/posts" `
  -Headers $headers `
  -Body '{"type":"USER_POST","title":"Hallo Nachbarn","body":"Testpost"}'
```

Erstelle einen offiziellen Post (Admin, News/Warnung).
```powershell
$headers = @{
  "Content-Type" = "application/json"
  "X-TENANT" = "hilders-demo"
  "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
  "X-ADMIN-KEY" = "HD-ADMIN-TEST-KEY"
}
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/admin/posts" `
  -Headers $headers `
  -Body '{"type":"NEWS","title":"Amtliche Info","body":"Inhalt","publishedAt":"2024-12-01T08:00:00.000Z"}'
```

Melde einen Beitrag und rufe die Moderation ab.
```powershell
# Report
$headers = @{
  "Content-Type" = "application/json"
  "X-TENANT" = "hilders-demo"
  "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
  "Authorization" = "Bearer <accessToken>"
}
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/posts/<postId>/report" `
  -Headers $headers `
  -Body '{}'

# Moderation (Backend-Route)
$headers = @{
  "X-TENANT" = "hilders-demo"
  "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
  "X-ADMIN-KEY" = "HD-ADMIN-TEST-KEY"
}
Invoke-RestMethod -Method Get -Uri "http://localhost:3000/admin/posts/reported" `
  -Headers $headers
```

Löse einen Tourist‑Code ein.
```powershell
$headers = @{
  "Content-Type" = "application/json"
  "X-TENANT" = "hilders-demo"
  "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
}
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/tourist/redeem" `
  -Headers $headers `
  -Body '{"code":"<touristCode>","deviceId":"device-123"}'
```

Troubleshooting‑Hinweise.
- **Port belegt**: API nutzt `3000`, Web‑Admin `3001`. Ändere den Port oder stoppe den Prozess.
- **403/401**: `X-TENANT`, `X-SITE-KEY`, `X-ADMIN-KEY` fehlen oder sind falsch.
- **404**: Route prüfen (z. B. Moderation ist `/admin/posts/...`, nicht `/api/admin/posts/...`).
- **Android Emulator**: API‑Base‑URL in der App ist `http://10.0.2.2:3000` (Debug/Demo).
