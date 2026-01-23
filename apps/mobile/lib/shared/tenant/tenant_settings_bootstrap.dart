import 'package:flutter/material.dart';

import 'tenant_settings_scope.dart';

class TenantSettingsBootstrap extends StatefulWidget {
  const TenantSettingsBootstrap({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<TenantSettingsBootstrap> createState() =>
      _TenantSettingsBootstrapState();
}

class _TenantSettingsBootstrapState extends State<TenantSettingsBootstrap> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final store = TenantSettingsScope.of(context);
    store.bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    final store = TenantSettingsScope.of(context);
    if (store.isLoading && !store.hasSettings) {
      return const _TenantLoadingScreen();
    }
    if (store.error != null && !store.hasSettings) {
      return _TenantErrorScreen(
        message: store.error ?? 'Unbekannter Fehler',
        onRetry: () => store.bootstrap(forceRefresh: true),
      );
    }
    return widget.child;
  }
}

class _TenantLoadingScreen extends StatelessWidget {
  const _TenantLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Gemeindedaten werden geladen...'),
          ],
        ),
      ),
    );
  }
}

class _TenantErrorScreen extends StatelessWidget {
  const _TenantErrorScreen({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Gemeindedaten konnten nicht geladen werden',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
