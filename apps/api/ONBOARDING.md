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
