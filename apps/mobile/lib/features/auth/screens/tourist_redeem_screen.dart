import 'package:flutter/material.dart';

import '../../../shared/auth/app_permissions.dart';
import '../../../shared/auth/auth_scope.dart';
import '../../../shared/auth/auth_store.dart';
import '../../../shared/di/app_services_scope.dart';

class TouristRedeemScreen extends StatefulWidget {
  const TouristRedeemScreen({super.key});

  @override
  State<TouristRedeemScreen> createState() => _TouristRedeemScreenState();
}

class _TouristRedeemScreenState extends State<TouristRedeemScreen> {
  final _codeController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authStore = AuthScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tourist-Zugang')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Tourist-Zugang',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Tourist-Code',
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
            child: Text(_submitting ? 'Bitte warten...' : 'Code einlösen'),
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
      final deviceId = await authStore.getOrCreateDeviceId();
      await authStore.redeemTourist(
        code: _codeController.text,
        deviceId: deviceId,
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
