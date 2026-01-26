# gemeinde_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

### Demo mode

Run the app with demo mode enabled:

```
flutter run --dart-define=DEMO_MODE=true
```

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Mobile auth flow manual checklist

1. Run the backend `docker compose` stack.
2. Seed a tenant and verify tenant settings load in the app.
3. Use the admin tooling to create a resident and activation code.
4. In the app, activate the account with the activation code.
5. Close and reopen the app to ensure the refresh flow signs you back in.
6. Use logout and confirm the app returns to the auth entry screen.
