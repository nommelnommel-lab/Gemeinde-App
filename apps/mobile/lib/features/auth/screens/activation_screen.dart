import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/app_config.dart';
import '../../../shared/auth/auth_scope.dart';
import '../../../shared/auth/auth_store.dart';
import '../../../shared/auth/activation_code_normalizer.dart';
import '../services/auth_service.dart';

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

  static final _activationCodeFormatter = TextInputFormatter.withFunction(
    (oldValue, newValue) {
      final normalized = normalizeActivationCode(newValue.text);
      return TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    },
  );

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
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [_activationCodeFormatter],
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
    final rawActivationCode = _activationCodeController.text;
    final normalizedActivationCode = normalizeActivationCode(rawActivationCode);
    if (normalizedActivationCode.isEmpty ||
        normalizedActivationCode.length < 8) {
      setState(() {
        _error = 'Bitte gib einen gültigen Aktivierungscode ein.';
      });
      return;
    }

    if (kDebugMode) {
      debugPrint(
        '[ACTIVATE] codeRawLen=${rawActivationCode.length} '
        'codeNormLen=${normalizedActivationCode.length} '
        'codeNorm="$normalizedActivationCode" '
        'runes=${normalizedActivationCode.runes.toList()} '
        'tenant=${AppConfig.tenantId} '
        'baseUrl=${AppConfig.apiBaseUrl}',
      );
    }

    _activationCodeController.value = TextEditingValue(
      text: normalizedActivationCode,
      selection: TextSelection.collapsed(offset: normalizedActivationCode.length),
    );
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await authStore.activate(
        activationCode: normalizedActivationCode,
        postalCode: _postalCodeController.text.trim(),
        houseNumber: _houseNumberController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      String message = error.toString();
      int? statusCode;
      if (error is AuthException) {
        message = error.message;
        statusCode = error.statusCode;
      }
      debugPrint('ACTIVATE FAILED status=${statusCode ?? 'unknown'} msg=$message');
      setState(() => _error = message);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}
