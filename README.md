# Gemeinde-App MVP

## Zusammenfassung (Stand)
- Mobile Startseite zeigt Nachbarschafts-Posts (Events/News); Warnungen erscheinen nicht mehr auf der Startseite, sondern im Warnungen-Tab.
- Rollenbasiertes Berechtigungsmodell (USER/STAFF/ADMIN) steuert offizielle Inhalte, Moderation und Bewohner-Verwaltung.

## Voraussetzungen
- Flutter SDK installiert (Windows)
- Docker Desktop installiert und laufend

## Mobile App starten (Windows)
1. In den Ordner der App wechseln:
   ```powershell
   cd apps\mobile
   ```
2. Abhängigkeiten laden:
   ```powershell
   flutter pub get
   ```
3. App starten:
   ```powershell
   flutter run
   ```

## Backend starten (Docker)
1. Beispiel-Umgebungsvariablen kopieren:
   ```powershell
   copy infra\.env.example infra\.env
   ```
2. Docker Compose starten:
   ```powershell
   cd infra
   docker compose up --build
   ```
3. Health-Check:
   ```powershell
   curl http://localhost:3000/health
   ```
4. Events-Endpoint:
   ```powershell
   curl http://localhost:3000/events
   ```
5. Event per ID:
   ```powershell
   curl http://localhost:3000/events/<id>
   ```
6. Event erstellen (STAFF/ADMIN, mit Auth-Token):
   ```powershell
   curl -X POST http://localhost:3000/events ^
     -H "Content-Type: application/json" ^
     -H "Authorization: Bearer <access-token>" ^
     -d "{\"title\":\"Konzert\",\"description\":\"Abend mit Musik\",\"date\":\"2024-12-01T19:00:00.000Z\",\"location\":\"Kirche\"}"
   ```
7. Event aktualisieren (STAFF/ADMIN):
   ```powershell
   curl -X PUT http://localhost:3000/events/<id> ^
     -H "Content-Type: application/json" ^
     -H "Authorization: Bearer <access-token>" ^
     -d "{\"title\":\"Konzert\",\"description\":\"Aktualisiert\",\"date\":\"2024-12-01T19:30:00.000Z\",\"location\":\"Kirche\"}"
   ```
8. Event löschen (STAFF/ADMIN):
   ```powershell
   curl -X DELETE http://localhost:3000/events/<id> ^
     -H "Authorization: Bearer <access-token>"
   ```

## Web Admin Panel (Bewohner & Aktivierungscodes)
1. In den Web-Admin-Ordner wechseln:
   ```powershell
   cd apps\web-admin
   ```
2. Beispiel-Umgebungsvariablen kopieren:
   ```powershell
   copy .env.example .env.local
   ```
3. Abhängigkeiten installieren:
   ```powershell
   npm install
   ```
4. Web-App starten:
   ```powershell
   npm run dev
   ```
5. Admin Panel öffnen: `http://localhost:3001`
6. Im Login:
   - Tenant, Site Key, Admin Key angeben.
   - Optional eine andere API Base URL (z. B. `http://localhost:3000`).
7. Funktionen:
   - **Bewohner**: Suchen, anlegen, Status prüfen.
   - **Import**: CSV hochladen und Import-Ergebnis prüfen.
   - **Codes**: Bewohner auswählen, Codes erzeugen, CSV exportieren oder kopieren.
   - **Rollen**: Rollen (USER/STAFF/ADMIN) per User ID oder E-Mail setzen.

## Berechtigungen & Content-Kategorien
**Öffentliche Inhalte:** Alle Nutzer sehen News, Warnungen, Events, Services und Orte.

**USER (Bürgerinnen/Bürger) dürfen Inhalte erstellen:**
- Online-Flohmarkt (Marketplace)
- Umzug/Entrümpelung
- Seniorenhilfe (Hilfeanfragen & Hilfsangebote)
- Café-Treff / Community-Meetups
- Kinderspiele
- Wohnungssuche
- Fundbüro (Lost & Found)
- Mitfahrgelegenheit
- Lokale Jobs
- Ehrenamt
- Verschenken
- Nachbarschaftshilfe / Skill-Tausch

**STAFF/ADMIN dürfen zusätzlich:**
- Offizielle News
- Offizielle Warnungen/Alerts
- Offizielle Events
- Gemeindeservices/Orte/Informationen verwalten
- Nutzerinhalte moderieren (verbergen/löschen/sperren)

## Rollen verwalten (Web-Admin)
Rollen werden über das Web-Admin-Panel im Tab **Rollen** gesetzt (Admin-Key erforderlich).

## Migration (User-Rollen)
Bestehende Nutzerinnen und Nutzer ohne Rolle können mit folgendem Script ergänzt werden:
```powershell
npx --prefix apps/api ts-node scripts/migrate-user-roles.ts
```

## Aktivierungscodes (Admin)
Admin-Aktivierungscodes werden tenant-spezifisch erzeugt und nur einmal im Response angezeigt.

**Codes erzeugen**
```powershell
curl -X POST http://localhost:3000/api/admin/activation-codes ^
  -H "Content-Type: application/json" ^
  -H "X-Tenant: hilders" ^
  -H "X-SITE-KEY: <site-key>" ^
  -H "X-ADMIN-KEY: <admin-key>" ^
  -d "{\"count\":2,\"expiresInDays\":30}"
```

**Beispiel-Response (Codes nur einmal sichtbar)**
```json
{
  "tenant": "hilders",
  "codes": [
    {
      "code": "HILD-3AN3-TQJ5",
      "expiresAt": "2026-02-28T00:00:00.000Z"
    }
  ]
}
```

**Beispiel Aktivierung**
```powershell
curl -X POST http://localhost:3000/api/auth/activate ^
  -H "Content-Type: application/json" ^
  -H "X-Tenant: hilders" ^
  -H "X-SITE-KEY: <site-key>" ^
  -d "{\"activationCode\":\"HILD-3AN3-TQJ5\",\"email\":\"user@example.com\",\"password\":\"Passwort123!\",\"postalCode\":\"12345\",\"houseNumber\":\"1A\"}"
```
Hinweis: Die postalCode/houseNumber-Werte müssen zu einem bekannten Bewohner des Tenants passen.

## Admin UI (Bewohner & Aktivierungscodes)
Die mobile App nutzt keinen Admin-Key im Produktivbetrieb. Bewohner- und Code-Verwaltung erfolgt über das Web-Admin-Panel.

## Test-Skript für Admin Flow
```powershell
$env:BASE_URL="http://localhost:3000"
$env:TENANT="hilders"
$env:SITE_KEY="<site-key>"
$env:ADMIN_KEY="<admin-key>"
npm --prefix apps/api run test:admin-flow
```

## Test-Skript für Rollen & Berechtigungen
```powershell
$env:BASE_URL="http://localhost:3000"
$env:TENANT="hilders"
$env:SITE_KEY="<site-key>"
$env:ADMIN_KEY="<admin-key>"
npm --prefix apps/api run test:role-permissions
```

## Ports
- API: `3000`
- PostgreSQL: `5432`
