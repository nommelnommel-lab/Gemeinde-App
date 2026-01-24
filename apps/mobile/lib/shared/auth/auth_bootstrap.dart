import 'package:flutter/material.dart';

import '../../features/auth/screens/auth_entry_screen.dart';
import '../di/app_services_scope.dart';
import 'app_permissions.dart';
import 'auth_scope.dart';

class AuthBootstrap extends StatefulWidget {
  const AuthBootstrap({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AuthBootstrap> createState() => _AuthBootstrapState();
}

class _AuthBootstrapState extends State<AuthBootstrap> {
  bool _started = false;
  bool _permissionsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    AuthScope.of(context).bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    final authStore = AuthScope.of(context);
    if (!authStore.isAuthenticated) {
      _permissionsLoaded = false;
    }
    if (authStore.isAuthenticated && !_permissionsLoaded) {
      _permissionsLoaded = true;
      AppServicesScope.of(context)
          .permissionsService
          .getPermissions()
          .then((permissions) {
        if (!mounted) return;
        AppPermissionsScope.controllerOf(context).setPermissions(permissions);
      }).catchError((_) {
        if (!mounted) return;
        AppPermissionsScope.controllerOf(context)
            .setPermissions(AppPermissions.empty);
      });
    }
    if (authStore.isLoading && !authStore.isAuthenticated) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Authentifizierung wird geprüft...'),
            ],
          ),
        ),
      );
    }

    if (!authStore.isAuthenticated) {
      return const AuthEntryScreen();
    }

    return widget.child;
  }
}
