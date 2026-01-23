import 'package:flutter/material.dart';

import '../../features/auth/screens/auth_entry_screen.dart';
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
