# Tenant Onboarding (5-minute checklist)

## Checklist
1. Add tenant mapping to `SITE_KEYS_JSON` (maps site key -> tenant ID).
2. Add admin mapping to `ADMIN_KEYS_JSON` (maps admin key -> tenant ID).
3. Set `JWT_SECRET` for auth token signing.
4. Run the seed helper to create tenant settings + empty content files.

```bash
cd apps/api
npm install
npm run seed:tenant -- <tenantId>
```

## Environment variables
- `SITE_KEYS_JSON` example:
  ```json
  {"HD-2026-9f3c1a2b-KEY":"hilders","NEW-2026-KEY":"new-town"}
  ```
- `ADMIN_KEYS_JSON` example:
  ```json
  {"ADMIN-KEY-1":"hilders","ADMIN-KEY-2":"new-town"}
  ```
- `JWT_SECRET` example:
  ```bash
  JWT_SECRET=dev-secret-change-me
  ```
  - Used to HMAC-hash activation codes and sign JWTs (changing it invalidates existing codes/tokens).

## What the seed helper does
- Ensures tenant settings exist and applies default feature flags.
- Ensures the per-tenant content files exist (events, posts, services, places, clubs, waste-pickups).
- Seeds test residents + activation codes for `hilders` and prints codes to stdout when not in production.

## Activation codes output
When running `npm run seed:tenant -- hilders` in non-production, activation codes are printed to stdout once per run.

## Auth curl examples
```bash
curl -X POST http://localhost:3000/api/admin/residents \
  -H "Content-Type: application/json" \
  -H "X-TENANT: hilders" \
  -H "X-SITE-KEY: HD-2026-9f3c1a2b-KEY" \
  -H "X-ADMIN-KEY: HD-ADMIN-TEST-KEY" \
  -d '{"firstName":"Florian","lastName":"Günkel","postalCode":"36115","houseNumber":"5"}'
```

```bash
curl -X POST http://localhost:3000/api/admin/activation-codes \
  -H "Content-Type: application/json" \
  -H "X-TENANT: hilders" \
  -H "X-SITE-KEY: HD-2026-9f3c1a2b-KEY" \
  -H "X-ADMIN-KEY: HD-ADMIN-TEST-KEY" \
  -d '{"residentId":"<residentId>","expiresInDays":30}'
```

```bash
curl -X POST http://localhost:3000/api/auth/activate \
  -H "Content-Type: application/json" \
  -H "X-TENANT: hilders" \
  -H "X-SITE-KEY: HD-2026-9f3c1a2b-KEY" \
  -d '{"activationCode":"<code>","email":"user@example.de","password":"secret123","postalCode":"36115","houseNumber":"5"}'
```

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -H "X-TENANT: hilders" \
  -H "X-SITE-KEY: HD-2026-9f3c1a2b-KEY" \
  -d '{"email":"user@example.de","password":"secret123"}'
```

```bash
curl -X POST http://localhost:3000/api/auth/refresh \
  -H "Content-Type: application/json" \
  -H "X-TENANT: hilders" \
  -H "X-SITE-KEY: HD-2026-9f3c1a2b-KEY" \
  -d '{"refreshToken":"<refreshToken>"}'
```

```bash
curl -X POST http://localhost:3000/api/auth/logout \
  -H "Content-Type: application/json" \
  -H "X-TENANT: hilders" \
  -H "X-SITE-KEY: HD-2026-9f3c1a2b-KEY" \
  -d '{"refreshToken":"<refreshToken>"}'
```

## Auth PowerShell examples
```powershell
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/admin/residents" `
  -Headers @{ "X-TENANT"="hilders"; "X-SITE-KEY"="HD-2026-9f3c1a2b-KEY"; "X-ADMIN-KEY"="HD-ADMIN-TEST-KEY" } `
  -ContentType "application/json" `
  -Body '{"firstName":"Florian","lastName":"Günkel","postalCode":"36115","houseNumber":"5"}'
```

```powershell
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/admin/activation-codes" `
  -Headers @{ "X-TENANT"="hilders"; "X-SITE-KEY"="HD-2026-9f3c1a2b-KEY"; "X-ADMIN-KEY"="HD-ADMIN-TEST-KEY" } `
  -ContentType "application/json" `
  -Body '{"residentId":"<residentId>","expiresInDays":30}'
```

```powershell
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/auth/activate" `
  -Headers @{ "X-TENANT"="hilders"; "X-SITE-KEY"="HD-2026-9f3c1a2b-KEY" } `
  -ContentType "application/json" `
  -Body '{"activationCode":"<code>","email":"user@example.de","password":"secret123","postalCode":"36115","houseNumber":"5"}'
```

```powershell
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/auth/login" `
  -Headers @{ "X-TENANT"="hilders"; "X-SITE-KEY"="HD-2026-9f3c1a2b-KEY" } `
  -ContentType "application/json" `
  -Body '{"email":"user@example.de","password":"secret123"}'
```

```powershell
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/auth/refresh" `
  -Headers @{ "X-TENANT"="hilders"; "X-SITE-KEY"="HD-2026-9f3c1a2b-KEY" } `
  -ContentType "application/json" `
  -Body '{"refreshToken":"<refreshToken>"}'
```

```powershell
Invoke-RestMethod -Method Post -Uri "http://localhost:3000/api/auth/logout" `
  -Headers @{ "X-TENANT"="hilders"; "X-SITE-KEY"="HD-2026-9f3c1a2b-KEY" } `
  -ContentType "application/json" `
  -Body '{"refreshToken":"<refreshToken>"}'
```
