# Gemeinde-App Monorepo

Gemeinde-App ist eine Multi‑Tenant Plattform für kommunale Inhalte mit einer NestJS‑API, einer Flutter‑Mobile‑App und einem Next.js Web‑Admin‑Panel – gebündelt in einem Monorepo.

## Architektur (High‑Level)
- **Backend (NestJS API)**: `apps/api` auf `http://localhost:3000`.
- **Mobile App (Flutter)**: `apps/mobile`.
- **Web‑Admin (Next.js)**: `apps/web-admin` auf `http://localhost:3001`.
- **Multi‑Tenant**: Mandantentrennung über Header `X-TENANT` + `X-SITE-KEY` (Admin zusätzlich `X-ADMIN-KEY`).

## Dokumentation
- **Projektstatus**: [docs/STATUS.md](docs/STATUS.md)
- **Commands / Runbooks (PowerShell)**: [docs/COMMANDS.md](docs/COMMANDS.md)
- **Environment & Header**: [docs/ENV.md](docs/ENV.md)
- **Demo‑Ablauf**: [docs/DEMO_STEPS.md](docs/DEMO_STEPS.md)

## Quick Start (TL;DR)
- **Starten & lokale Befehle**: siehe [docs/COMMANDS.md](docs/COMMANDS.md)
- **Demo‑Ablauf**: siehe [docs/DEMO_STEPS.md](docs/DEMO_STEPS.md)
