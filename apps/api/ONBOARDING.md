# Tenant Onboarding (5-minute checklist)

## Checklist
1. Add tenant mapping to `SITE_KEYS_JSON` (maps site key -> tenant ID).
2. Add admin mapping to `ADMIN_KEYS_JSON` (maps admin key -> tenant ID).
3. Run the seed helper to create tenant settings + empty content files.

```bash
cd apps/api
npm install
npm run seed:tenant -- <tenantId>
```

> Hinweis: Wenn der bcrypt Native Build auf Alpine fehlschlägt, installiere die benötigten Build-Abhängigkeiten (z.B. `python3`, `make`, `g++`) oder wechsle alternativ auf `argon2`.

## Environment variables
- `SITE_KEYS_JSON` example:
  ```json
  {"HD-2026-9f3c1a2b-KEY":"hilders","NEW-2026-KEY":"new-town"}
  ```
- `ADMIN_KEYS_JSON` example:
  ```json
  {"ADMIN-KEY-1":"hilders","ADMIN-KEY-2":"new-town"}
  ```

## What the seed helper does
- Ensures tenant settings exist and applies default feature flags.
- Ensures the per-tenant content files exist (events, posts, services, places, clubs, waste-pickups).

## Admin resident & activation code flow

### Create a resident (curl)
```bash
curl -X POST http://localhost:3000/api/admin/residents \
  -H "Content-Type: application/json" \
  -H "X-TENANT: hilders" \
  -H "X-SITE-KEY: HD-2026-9f3c1a2b-KEY" \
  -H "X-ADMIN-KEY: ADMIN-KEY-1" \
  -d '{"firstName":"Anna","lastName":"Muster","postalCode":"36115","houseNumber":"12A"}'
```

### Create a resident (PowerShell)
```powershell
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/admin/residents" `
  -Headers @{
    "Content-Type" = "application/json"
    "X-TENANT" = "hilders"
    "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
    "X-ADMIN-KEY" = "ADMIN-KEY-1"
  } `
  -Body '{"firstName":"Anna","lastName":"Muster","postalCode":"36115","houseNumber":"12A"}'
```

### List residents (PowerShell)
```powershell
Invoke-RestMethod -Method Get -Uri "http://localhost:3000/api/admin/residents?q=mus&limit=50" `
  -Headers @{
    "X-TENANT" = "hilders"
    "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
    "X-ADMIN-KEY" = "ADMIN-KEY-1"
  }
```

### Create an activation code (PowerShell)
```powershell
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/admin/activation-codes" `
  -Headers @{
    "Content-Type" = "application/json"
    "X-TENANT" = "hilders"
    "X-SITE-KEY" = "HD-2026-9f3c1a2b-KEY"
    "X-ADMIN-KEY" = "ADMIN-KEY-1"
  } `
  -Body '{"residentId":"<residentId>","expiresInDays":14}'
```
