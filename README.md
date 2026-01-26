# Gemeinde-App

Gemeinde-App ist eine Multi-Tenant-Plattform für kommunale Inhalte. Sie richtet sich an Kommunen und deren Bürger:innen und umfasst eine Backend-API, eine Mobile-App sowie ein Web-Admin-Panel.

## Architektur (High-Level)
- **Backend (NestJS, Docker, Multi-Tenant)**: API in `apps/api`, betrieben via Docker Compose. Multi-Tenant über Header `X-TENANT`, `X-SITE-KEY` (Admin zusätzlich `X-ADMIN-KEY`).
- **Mobile App (Flutter, Android/iOS)**: App in `apps/mobile`.
- **Web-Admin (Next.js)**: Admin-UI in `apps/web-admin` auf `http://localhost:3001`.

## Dokumentation
- **Status**: [docs/STATUS.md](docs/STATUS.md)
- **Commands / Runbooks**: [docs/COMMANDS.md](docs/COMMANDS.md)
- **Environment & Header**: [docs/ENV.md](docs/ENV.md)
- **Demo-Ablauf**: [docs/DEMO_STEPS.md](docs/DEMO_STEPS.md)

## Quick Start
- **Lokale Befehle & Runbooks**: siehe [docs/COMMANDS.md](docs/COMMANDS.md)
- **Geführter Demo-Ablauf**: siehe [docs/DEMO_STEPS.md](docs/DEMO_STEPS.md)
