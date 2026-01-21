# Gemeinde-App MVP

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

## Ports
- API: `3000`
- PostgreSQL: `5432`
