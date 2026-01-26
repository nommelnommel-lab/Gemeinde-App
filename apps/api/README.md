# API

## Test activation flow

The activation-flow script expects the tenant and keys from environment variables. It stops early with a clear message if SITE/ADMIN keys are missing.

### Windows PowerShell example

```powershell
$env:SITE_KEY="HD-2026-9f3c1a2b-KEY"
$env:ADMIN_KEY="HD-ADMIN-TEST-KEY"
$env:TENANT="hilders"
$env:BASE_URL="http://localhost:3000"
$env:DEBUG="1"
npm --prefix apps/api run test:activation-flow
```

### Notes

* `SITE_KEY` can also be provided as `X_SITE_KEY`.
* `ADMIN_KEY` can also be provided as `X_ADMIN_KEY`.
* `DEBUG=1` enables masked header debug output.

## Seed demo tourism data (Hilders)

```bash
TENANT=hilders-demo npm --prefix apps/api run seed:tourism:hilders
```

To seed the full Hilders demo dataset (profile, forms, tourism):

```bash
TENANT=hilders-demo npm --prefix apps/api run seed:hilders
```

## Seed demo tenant data (hilders-demo)

The demo seed uses the API and requires these environment variables:

* `BASE_URL` (default: `http://localhost:3000`)
* `SITE_KEY` (or `X_SITE_KEY`)
* `ADMIN_KEY` (or `X_ADMIN_KEY`)

Run the seed script:

```bash
BASE_URL=http://localhost:3000 \
SITE_KEY=HD-2026-9f3c1a2b-KEY \
ADMIN_KEY=HD-ADMIN-TEST-KEY \
npm --prefix apps/api run seed:hilders-demo
```
