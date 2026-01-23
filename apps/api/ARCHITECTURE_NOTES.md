# Backend Architecture Notes (Phase B0)

## Modules & controllers (municipality)
- Feed: `src/municipality/feed/municipality-feed.controller.ts`
- Events: `src/municipality/events/municipality-events.controller.ts`
- Posts (news + warnings): `src/municipality/posts/municipality-posts.controller.ts`
- Services: `src/municipality/services/municipality-services.controller.ts`
- Places: `src/municipality/places/municipality-places.controller.ts`
- Clubs: `src/municipality/clubs/municipality-clubs.controller.ts`
- Waste pickups: `src/municipality/waste-pickups/municipality-waste-pickups.controller.ts`
- Tenant settings: `src/municipality/tenant-settings/tenant-settings.controller.ts`

## Tenant auth
- Tenant/site-key mapping is enforced in `src/tenant/tenant-auth.ts` via `X-TENANT` + `X-SITE-KEY` against `SITE_KEYS_JSON`.

## Existing admin endpoints
- Admin CRUD exists under `/api/admin/*` for events, posts, services, places, clubs, and waste pickup bulk import.
