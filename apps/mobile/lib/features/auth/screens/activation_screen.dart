import 'package:flutter/material.dart';

import '../../../shared/auth/auth_scope.dart';
import '../../../shared/auth/auth_store.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _activationCodeController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _houseNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _activationCodeController.dispose();
    _postalCodeController.dispose();
    _houseNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authStore = AuthScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Aktivierung')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Aktiviere deinen Zugang',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _activationCodeController,
            decoration: const InputDecoration(
              labelText: 'Aktivierungscode',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _postalCodeController,
                  decoration: const InputDecoration(
                    labelText: 'PLZ',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _houseNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Hausnummer',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
            onPressed: _submitting
                ? null
                : () => _submit(authStore),
            child: Text(_submitting ? 'Bitte warten...' : 'Aktivieren'),
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
      await authStore.activate(
        activationCode: _activationCodeController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        houseNumber: _houseNumberController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
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
