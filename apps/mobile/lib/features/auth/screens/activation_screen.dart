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
  String? _activationCodeError;
  String? _postalCodeError;
  String? _houseNumberError;
  String? _emailError;
  String? _passwordError;

  static const int _minPasswordLength = 8;
  static final RegExp _activationCodeFormat =
      RegExp(r'^[A-Z0-9]+(?:-[A-Z0-9]+)*$');
  static final RegExp _postalCodeFormat = RegExp(r'^\d{5}$');
  static final RegExp _houseNumberFormat = RegExp(r'^[A-Za-z0-9]+$');
  static final RegExp _emailFormat =
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

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
            decoration: InputDecoration(
              labelText: 'Aktivierungscode',
              errorText: _activationCodeError,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _postalCodeController,
                  decoration: InputDecoration(
                    labelText: 'PLZ',
                    errorText: _postalCodeError,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _houseNumberController,
                  decoration: InputDecoration(
                    labelText: 'Hausnummer',
                    errorText: _houseNumberError,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'E-Mail',
              errorText: _emailError,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Passwort',
              helperText: 'Mindestens $_minPasswordLength Zeichen',
              errorText: _passwordError,
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

  bool _validateInputs({
    required String activationCode,
    required String postalCode,
    required String houseNumber,
    required String email,
    required String password,
  }) {
    String? activationCodeError;
    String? postalCodeError;
    String? houseNumberError;
    String? emailError;
    String? passwordError;

    if (activationCode.isEmpty) {
      activationCodeError = 'Bitte gib einen Aktivierungscode ein.';
    } else if (!_activationCodeFormat.hasMatch(activationCode)) {
      activationCodeError = 'Bitte prüfe den Code (Format).';
    } else if (activationCode.length < 8) {
      activationCodeError = 'Bitte gib einen gültigen Aktivierungscode ein.';
    }

    if (!_postalCodeFormat.hasMatch(postalCode)) {
      postalCodeError = 'Bitte gib eine gültige PLZ ein.';
    }

    if (houseNumber.isEmpty) {
      houseNumberError = 'Bitte gib eine Hausnummer ein.';
    } else if (!_houseNumberFormat.hasMatch(houseNumber)) {
      houseNumberError = 'Hausnummer darf nur Buchstaben/Ziffern enthalten.';
    }

    if (email.isEmpty) {
      emailError = 'Bitte gib deine E-Mail ein.';
    } else if (!_emailFormat.hasMatch(email)) {
      emailError = 'Bitte gib eine gültige E-Mail ein.';
    }

    if (password.isEmpty) {
      passwordError = 'Bitte gib ein Passwort ein.';
    } else if (password.length < _minPasswordLength) {
      passwordError = 'Passwort ist zu kurz.';
    }

    setState(() {
      _activationCodeError = activationCodeError;
      _postalCodeError = postalCodeError;
      _houseNumberError = houseNumberError;
      _emailError = emailError;
      _passwordError = passwordError;
      if (activationCodeError != null ||
          postalCodeError != null ||
          houseNumberError != null ||
          emailError != null ||
          passwordError != null) {
        _error = null;
      }
    });

    return activationCodeError == null &&
        postalCodeError == null &&
        houseNumberError == null &&
        emailError == null &&
        passwordError == null;
  }

  String _mapActivationError(AuthException error) {
    final message = error.message;
    final statusCode = error.statusCode;

    if (statusCode == 400 &&
        message.contains('Aktivierungscode Format ungültig')) {
      return 'Bitte prüfe den Code (Format).';
    }
    if (statusCode == 401 && message.contains('Aktivierungscode ungültig')) {
      return 'Code ungültig/abgelaufen/benutzt.';
    }
    if (statusCode == 404 && message.contains('Bewohner nicht gefunden')) {
      return 'PLZ/Hausnummer passt nicht zum Code.';
    }
    if (statusCode == 409 && message.contains('E-Mail ist bereits registriert')) {
      return 'E-Mail bereits registriert. Bitte Login nutzen.';
    }
    return 'Fehler. Bitte später erneut versuchen.';
  }

  Future<void> _submit(AuthStore authStore) async {
    final rawActivationCode = _activationCodeController.text;
    final normalizedActivationCode = normalizeActivationCode(rawActivationCode);
    if (normalizedActivationCode != rawActivationCode) {
      _activationCodeController.value = TextEditingValue(
        text: normalizedActivationCode,
        selection:
            TextSelection.collapsed(offset: normalizedActivationCode.length),
      );
    }
    final rawPostalCode = _postalCodeController.text.trim();
    final rawHouseNumber = _houseNumberController.text.trim();
    final sanitizedHouseNumber =
        rawHouseNumber.replaceAll(RegExp(r'\s+'), '');
    final rawEmail = _emailController.text.trim();
    final rawPassword = _passwordController.text;
    final isValid = _validateInputs(
      activationCode: normalizedActivationCode,
      postalCode: rawPostalCode,
      houseNumber: sanitizedHouseNumber,
      email: rawEmail,
      password: rawPassword,
    );
    if (!isValid) {
      return;
    }

    if (kDebugMode) {
      debugPrint(
        '[ACTIVATE] activationCodeLength=${normalizedActivationCode.length} '
        'tenant=${AppConfig.tenantId}',
      );
    }
    if (sanitizedHouseNumber != rawHouseNumber) {
      _houseNumberController.value = TextEditingValue(
        text: sanitizedHouseNumber,
        selection:
            TextSelection.collapsed(offset: sanitizedHouseNumber.length),
      );
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await authStore.activate(
        activationCode: normalizedActivationCode,
        postalCode: rawPostalCode,
        houseNumber: sanitizedHouseNumber,
        email: rawEmail,
        password: rawPassword,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      String message = 'Fehler. Bitte später erneut versuchen.';
      int? statusCode;
      if (error is AuthException) {
        message = _mapActivationError(error);
        statusCode = error.statusCode;
      }
      debugPrint('ACTIVATE FAILED status=${statusCode ?? 'unknown'}');
      setState(() => _error = message);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}
