# Mobile App Architecture Notes (Phase A0)

## Framework
- Flutter app (see `pubspec.yaml`).

## HTTP client
- Central API client: `lib/api/api_client.dart` using `package:http`.

## Navigation
- Entry point: `lib/main.dart` -> `MainNavigationScreen`.
- Tabs: Start, Warnungen, GemeindeApp, Verwaltung, Mehr (`features/navigation/screens/main_navigation_screen.dart`).

## Tenant + site key storage
- Tenant ID stored in `SharedPreferences` via `TenantStore` (`lib/shared/tenant/tenant_store.dart`).
- Site key currently sourced from `AppConfig.siteKey` (`lib/config/app_config.dart`).
