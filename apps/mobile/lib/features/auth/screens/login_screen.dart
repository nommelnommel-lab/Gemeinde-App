import 'package:flutter/material.dart';

import '../../../shared/auth/app_permissions.dart';
import '../../../shared/auth/auth_scope.dart';
import '../../../shared/auth/auth_store.dart';
import '../../../shared/di/app_services_scope.dart';
import '../../../shared/navigation/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authStore = AuthScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Login',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-Mail',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Passwort',
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _submitting ? null : () => _submit(authStore),
            child: Text(_submitting ? 'Bitte warten...' : 'Login'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(AuthStore authStore) async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await authStore.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final permissions =
          await AppServicesScope.of(context).permissionsService.getPermissions();
      if (!mounted) return;
      AppPermissionsScope.controllerOf(context).setPermissions(permissions);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}
