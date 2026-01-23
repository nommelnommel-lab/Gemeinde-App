# Auth Backend Audit (Phase 0)

## Persistence approach
- Data is stored as JSON files per tenant under `data/tenants/<tenantId>/`.
- The API uses `TenantFileRepository` for read/write access and seeding.

## Existing modules
- `AppModule` composes feature modules under `src/*`, including municipality, tenant, and auth.
- Controllers mount routes under `/api/*` and `requireTenant` enforces `X-TENANT` + `X-SITE-KEY`.

## Admin guard pattern
- Admin endpoints are protected via `AdminGuard` (header `X-ADMIN-KEY`) using `@UseGuards(AdminGuard)`.
