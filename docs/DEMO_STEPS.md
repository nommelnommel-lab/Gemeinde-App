# Demo Steps (DE)

## Ablauf (copy‑paste‑fähig)

1) **Backend starten (API + DB)**
```powershell
Push-Location infra
Copy-Item .env.example .env -Force
docker compose up -d --build
Pop-Location
```

2) **Seed hilders-demo (optional, je nach Demo‑Stand)**
```powershell
npm --prefix apps/api run seed:hilders
npm --prefix apps/api run seed:demo
npm --prefix apps/api run seed:hilders-demo
```

3) **Web‑Admin starten (`http://localhost:3001`)**
```powershell
npm --prefix apps/web-admin install
npm --prefix apps/web-admin run dev -p 3001
```

4) **Mobile starten (Demo‑Mode oder Tourist)**
```powershell
Set-Location apps\mobile
flutter pub get
flutter run --dart-define=DEMO_MODE=true
```

5) **Was du während der Live‑Präsentation klickst**
   - **Mobile Startfeed** öffnen → Events/News/Warnungen prüfen.
   - **Bürgerbeiträge** → Beitrag öffnen, ggf. neuen Beitrag erstellen.
   - **Moderation (Staff‑Modus)** → Beitrag öffnen → bearbeiten/löschen.
   - **Verwaltung** → „Öffnungszeiten & Kontakt“ prüfen → Website‑Link öffnen.
   - **Web‑Admin** → Login → Inhalte (Event/News/Warnung) anlegen → speichern → Liste aktualisiert.
   - **Web‑Admin Moderation** → Beitrag melden/ausblenden → Status wechselt.
   - **Codes/Residents** → CSV exportieren (Komma/Semikolon).
   - **Health Indicator** → Backend‑Status prüfen, bei Fehler Retry.

## Erwartetes Verhalten (Beispiel Moderation)
1. **Citizen Post** melden.
2. **Admin Moderation** → Beitrag „Verbergen“.
3. **Mobile** → Beitrag verschwindet aus der Liste.
4. **Admin Moderation** → Beitrag „Einblenden“ → Beitrag erscheint wieder.

## Checkliste: Wenn etwas nicht erscheint
- **API erreichbar?** `http://localhost:3000/health`
- **Web‑Admin erreichbar?** `http://localhost:3001`
- **Headers gesetzt?** `X-TENANT`, `X-SITE-KEY`, optional `X-ADMIN-KEY`.
- **Tenant korrekt?** Demo nutzt `hilders-demo`.
- **Routen prüfen**: Moderation nutzt `/admin/posts/...` (Backend), nicht `/api/admin/posts/...`.
