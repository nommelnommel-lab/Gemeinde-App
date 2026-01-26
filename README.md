# Gemeinde-App Monorepo

Die Gemeinde-App ist ein Monorepo für die mobile Flutter-App, die NestJS-API und das Next.js Web-Admin-Panel.

## Schnellüberblick
- **API (NestJS)**: `apps/api` (läuft standardmäßig auf `http://localhost:3000`).
- **Mobile App (Flutter)**: `apps/mobile`.
- **Web-Admin (Next.js)**: `apps/web-admin` (Dev-Server auf `http://localhost:3001`).
- **Infra / Docker Compose**: `infra/docker-compose.yml` (Postgres + API).

## Dokumentation
- **Projektstatus & Features**: `docs/STATUS.md`
- **Befehle & Runbooks (PowerShell)**: `docs/COMMANDS.md`
- **Umgebungsvariablen & Beispiele (PowerShell)**: `docs/ENV.md`

## Einstieg
1. Backend mit Docker starten (`infra/docker-compose.yml`).
2. Web-Admin starten (`apps/web-admin`).
3. Mobile App starten (`apps/mobile`).

Details, API-Endpunkte und Test-Requests findest du in `docs/COMMANDS.md`.
