# Projektstatus

## Architektur-Überblick (Ist-Zustand)
- **Monorepo-Layout**
  - `apps/api`: NestJS API.
  - `apps/mobile`: Flutter App.
  - `apps/web-admin`: Next.js Web-Admin.
  - `infra`: Docker Compose (Postgres + API).
- **Ports**
  - API: `3000` (Container-Port `3000`).
  - Web-Admin: `3001` (Next.js Dev-Server).
- **Docker Compose**
  - Datei: `infra/docker-compose.yml`.
  - Services: `postgres`, `api` (API baut aus `apps/api`).
- **Multi-Tenant Header**
  - **Pflicht**: `X-TENANT` + `X-SITE-KEY` (abgeglichen gegen `SITE_KEYS_JSON`).
  - **Admin**: zusätzlich `X-ADMIN-KEY` (abgeglichen gegen `ADMIN_KEYS_JSON`).
- **Auth-Modi**
  - **Resident Activation**: `/api/auth/activate` (Activation-Code + Adresse).
  - **Login**: `/api/auth/login` (Email/Passwort).
  - **Tourist Flow**: `/api/tourist/redeem` (Tourist-Code + Device-ID).
  - **Demo-Mode (Mobile)**: Flutter `--dart-define=DEMO_MODE=true` (Demo-Tenant + Demo-Site-Key).
- **Berechtigungsmodell**
  - API liefert Berechtigungen via `GET /permissions` (Role + Create-Permissions + Admin-Rechte).
  - Mobile UI nutzt `AppPermissions` für Gatekeeping (z. B. Create-Buttons, Staff-Modus).

## Feature-Status

### Backend (NestJS)
| Bereich | Status | Hinweise |
| --- | --- | --- |
| Health | ✅ | `GET /health` liefert `{status:"ok"}`. |
| Auth (Activation/Login/Refresh/Logout) | ✅ | `/api/auth/*` Endpoints vorhanden. |
| Permissions | ✅ | `GET /permissions`. |
| Posts (Bürger-Posts) | ✅ | `/posts` inkl. Create/Update/Delete/Report. |
| Moderation (Bürger-Posts) | ✅ | `/admin/posts/*` inkl. reported/hide/unhide/reset. |
| Tourismus | ✅ | `/api/tourism` + `/api/admin/tourism`. |
| Verwaltung | ✅ | `/api/verwaltung/items` + Admin-CRUD. |
| Demo-Reset | ✅ | `/api/admin/demo/reset` für `hilders-demo`. |

### Mobile (Flutter)
| Bereich | Status | Hinweise |
| --- | --- | --- |
| Activation/Login | ✅ | Auth-Entry mit Activation, Login, Tourist-Flow. |
| Tourist Flow | ✅ | Tourist Redeem via `/api/tourist/redeem`. |
| Navigation Tabs | ✅ | Tab-Layout abhängig von Tenant-Features + Tourist-Rolle. |
| Startfeed | ✅ | `/api/feed` aggregiert Events/Posts/Services. |
| Events / News / Warnings | ✅ | Events via `/api/feed/events`, News via `/news`, Warnings via `/warnings`. |
| Citizen Posts | ✅ | `/posts` + Report `/posts/:id/report`. |
| Create/Edit/Report | ✅ | Bürger-Posts inkl. Edit/Delete/Report. |
| Verwaltung | ✅ | Verwaltung-Hub + Items über `/api/verwaltung/items`. |
| Tourism Tab | ✅ | Tourist-Tab zeigt `/api/tourism` Inhalte. |
| Demo Mode | ✅ | `DEMO_MODE` nutzt Demo-Tenant + Demo-Site-Key. |

### Web-Admin (Next.js)
| Bereich | Status | Hinweise |
| --- | --- | --- |
| Login | ✅ | Validiert via `GET /api/admin/users`. |
| Residents | ✅ | `GET/POST /api/admin/residents`. |
| Import | ✅ | `POST /api/admin/residents/import`. |
| Codes | ✅ | `POST /api/admin/activation-codes/bulk`. |
| Tourist-Codes | ✅ | `GET/POST /api/admin/tourist-codes` + revoke. |
| Roles | ✅ | `POST /api/admin/users/role`. |
| Content (News/Events/Warnungen) | ✅ | `GET/POST/PATCH/DELETE /api/admin/events` + `/api/admin/posts`. |
| Moderation | ⚠️ | UI nutzt `/api/admin/posts/reported`, Backend bietet `/admin/posts/reported`. |
| Tourism Management | ✅ | `GET/POST/PATCH/DELETE /api/admin/tourism`. |
| Demo Reset | ⚠️ | `POST /api/admin/demo/reset` nur für Tenant `hilders-demo`. |

## Bekannte Auffälligkeiten aus TODOs/Kommentaren
- Flutter-Plattform-Projekte enthalten noch Template-TODOs (z. B. Android Application-ID, Release-Signing). Diese sind keine App-Logik, aber für Releases offen.
