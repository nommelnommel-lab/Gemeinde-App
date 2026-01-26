# Projektstatus

**Kurzantwort – was kann ich zeigen?**
- ✅ Backend-API ist funktionsfähig (Auth, Posts, Moderation, Verwaltung, Tourismus).
- ✅ Mobile App zeigt Feed, Posts, Verwaltung und Tourist-Flow.
- ✅ Web-Admin kann Inhalte, Residents und Codes verwalten.
- ⚠️ Moderation im Web-Admin nutzt eine abweichende Backend-Route (siehe Web-Admin).

## Backend

### Status-Überblick
- ✅ **Working**: Health, Auth (Activation/Login/Refresh/Logout), Permissions, Posts, Moderation, Tourismus, Verwaltung.
- ⚠️ **Partial**: Keine bekannten Teilfunktionen, siehe Hinweise unten.
- ❌ **Missing**: Keine bekannten fehlenden Kernfunktionen.

### Architektur-Überblick (Ist-Zustand)
- **Monorepo-Layout**
  - `apps/api`: NestJS API.
  - `apps/mobile`: Flutter App.
  - `apps/web-admin`: Next.js Web-Admin.
  - `infra`: Docker Compose (Postgres + API).
- **Ports**
  - API: `http://localhost:3000` (Container-Port `3000`).
  - Web-Admin: `http://localhost:3001` (Next.js Dev-Server).
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
  - Mobile UI nutzt `AppPermissions` für Gatekeeping (z. B. Create-Buttons, Staff-Modus).

### Feature-Status
| Bereich | Status | Hinweise |
| --- | --- | --- |
| Health | ✅ Working | `GET /health` liefert `{status:"ok"}`. |
| Auth (Activation/Login/Refresh/Logout) | ✅ Working | `/api/auth/*` Endpoints vorhanden. |
| Permissions | ✅ Working | `GET /permissions`. |
| Posts (Bürger-Posts) | ✅ Working | `/posts` inkl. Create/Update/Delete/Report. |
| Moderation (Bürger-Posts) | ✅ Working | `/admin/posts/*` inkl. reported/hide/unhide/reset. |
| Tourismus | ✅ Working | `/api/tourism` + `/api/admin/tourism`. |
| Verwaltung | ✅ Working | `/api/verwaltung/items` + Admin-CRUD. |

## Mobile App

### Status-Überblick
- ✅ **Working**: Activation/Login, Tourist-Flow, Navigation Tabs, Startfeed, Events/News/Warnungen, Citizen Posts, Create/Edit/Report, Verwaltung, Tourism Tab.
- ⚠️ **Partial**: Keine bekannten Teilfunktionen.
- ❌ **Missing**: Keine bekannten fehlenden Kernfunktionen.

### Feature-Status
| Bereich | Status | Hinweise |
| --- | --- | --- |
| Activation/Login | ✅ Working | Auth-Entry mit Activation, Login, Tourist-Flow. |
| Tourist Flow | ✅ Working | Tourist Redeem via `/api/tourist/redeem`. |
| Navigation Tabs | ✅ Working | Tab-Layout abhängig von Tenant-Features + Tourist-Rolle. |
| Startfeed | ✅ Working | `/api/feed` aggregiert Events/Posts/Services. |
| Events / News / Warnings | ✅ Working | Events via `/api/feed/events`, News via `/news`, Warnings via `/warnings`. |
| Citizen Posts | ✅ Working | `/posts` + Report `/posts/:id/report`. |
| Create/Edit/Report | ✅ Working | Bürger-Posts inkl. Edit/Delete/Report. |
| Verwaltung | ✅ Working | Verwaltung-Hub + Items über `/api/verwaltung/items`. |
| Tourism Tab | ✅ Working | Tourist-Tab zeigt `/api/tourism` Inhalte. |

## Web-Admin

### Status-Überblick
- ✅ **Working**: Login, Residents, Import, Codes, Tourist-Codes, Roles, Content, Tourism Management.
- ⚠️ **Partial**: Moderation-UI nutzt `/api/admin/posts/reported`, Backend bietet `/admin/posts/reported`.
- ❌ **Missing**: Keine bekannten fehlenden Kernfunktionen.

### Feature-Status
| Bereich | Status | Hinweise |
| --- | --- | --- |
| Login | ✅ Working | Validiert via `GET /api/admin/users`. |
| Residents | ✅ Working | `GET/POST /api/admin/residents`. |
| Import | ✅ Working | `POST /api/admin/residents/import`. |
| Codes | ✅ Working | `POST /api/admin/activation-codes/bulk`. |
| Tourist-Codes | ✅ Working | `GET/POST /api/admin/tourist-codes` + revoke. |
| Roles | ✅ Working | `POST /api/admin/users/role`. |
| Content (News/Events/Warnungen) | ✅ Working | `GET/POST/PATCH/DELETE /api/admin/events` + `/api/admin/posts`. |
| Moderation | ⚠️ Partial | UI nutzt `/api/admin/posts/reported`, Backend bietet `/admin/posts/reported`. |
| Tourism Management | ✅ Working | `GET/POST/PATCH/DELETE /api/admin/tourism`. |

## Demo Tenant (hilders-demo)

### Status-Überblick
- ✅ **Working**: Demo-Mode (Mobile), Demo-Reset (Backend).
- ⚠️ **Partial**: Demo-Reset (Web-Admin) gilt nur für `hilders-demo`.
- ❌ **Missing**: Keine bekannten fehlenden Kernfunktionen.

### Feature-Status
| Bereich | Status | Hinweise |
| --- | --- | --- |
| Demo-Mode (Mobile) | ✅ Working | `DEMO_MODE` nutzt Demo-Tenant + Demo-Site-Key. |
| Demo-Reset (Backend) | ✅ Working | `/api/admin/demo/reset` für `hilders-demo`. |
| Demo-Reset (Web-Admin) | ⚠️ Partial | `POST /api/admin/demo/reset` nur für Tenant `hilders-demo`. |

## Known Issues / Open Todos
- Flutter-Plattform-Projekte enthalten noch Template-TODOs (z. B. Android Application-ID, Release-Signing). Diese sind keine App-Logik, aber für Releases offen.
