# Gemeinde-App MVP

## Zusammenfassung (Stand)
- Mobile Startseite zeigt Nachbarschafts-Posts (Events/News); Warnungen erscheinen nicht mehr auf der Startseite, sondern im Warnungen-Tab.

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
6. Event erstellen:
   ```powershell
   curl -X POST http://localhost:3000/events ^
     -H "Content-Type: application/json" ^
     -d "{\"title\":\"Konzert\",\"description\":\"Abend mit Musik\",\"date\":\"2024-12-01T19:00:00.000Z\",\"location\":\"Kirche\"}"
   ```
7. Event aktualisieren:
   ```powershell
   curl -X PUT http://localhost:3000/events/<id> ^
     -H "Content-Type: application/json" ^
     -d "{\"title\":\"Konzert\",\"description\":\"Aktualisiert\",\"date\":\"2024-12-01T19:30:00.000Z\",\"location\":\"Kirche\"}"
   ```
8. Event löschen:
   ```powershell
   curl -X DELETE http://localhost:3000/events/<id>
   ```

## Ports
- API: `3000`
- PostgreSQL: `5432`
