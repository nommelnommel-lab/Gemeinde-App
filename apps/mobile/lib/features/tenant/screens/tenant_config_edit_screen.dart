import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../api/api_client.dart';
import '../../../config/app_config.dart';
import '../../../shared/auth/admin_key_store.dart';
import '../../../shared/di/app_services_scope.dart';
import '../models/tenant_config.dart';
import '../services/tenant_service.dart';

class TenantConfigEditScreen extends StatefulWidget {
  const TenantConfigEditScreen({
    super.key,
    required this.initialConfig,
    this.adminKeyOverride,
  });

  final TenantConfig initialConfig;
  final String? adminKeyOverride;

  @override
  State<TenantConfigEditScreen> createState() =>
      _TenantConfigEditScreenState();
}

class _TenantConfigEditScreenState extends State<TenantConfigEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;
  bool _saving = false;
  late TenantService _tenantService;
  late AdminKeyStore _adminKeyStore;

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;

  final List<_OpeningHoursEntry> _openingHoursEntries = [];
  final List<TextEditingController> _emergencyControllers = [];

  String? _adminKeyOverride;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final services = AppServicesScope.of(context);
    _tenantService = services.tenantService;
    _adminKeyStore = services.adminKeyStore;
    _adminKeyOverride = widget.adminKeyOverride;

    _nameController = TextEditingController(text: widget.initialConfig.name);
    _addressController =
        TextEditingController(text: widget.initialConfig.address);
    _phoneController = TextEditingController(text: widget.initialConfig.phone);
    _emailController = TextEditingController(text: widget.initialConfig.email);
    _websiteController =
        TextEditingController(text: widget.initialConfig.website);

    for (final entry in widget.initialConfig.openingHours) {
      _openingHoursEntries.add(_OpeningHoursEntry.fromModel(entry));
    }

    for (final number in widget.initialConfig.emergencyNumbers) {
      _emergencyControllers.add(TextEditingController(text: number));
    }

    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    for (final entry in _openingHoursEntries) {
      entry.dispose();
    }
    for (final controller in _emergencyControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemeinde bearbeiten'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('Basisdaten'),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name ist erforderlich.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Adresse'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Telefon'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-Mail'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) return null;
                final isValid = RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                    .hasMatch(trimmed);
                if (!isValid) {
                  return 'Bitte eine gültige E-Mail eingeben.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(labelText: 'Website'),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Öffnungszeiten'),
            if (_openingHoursEntries.isEmpty)
              const Text('Keine Öffnungszeiten vorhanden.'),
            ..._openingHoursEntries.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _OpeningHoursCard(
                entry: item,
                onRemove: () => _removeOpeningHour(index),
                onChanged: () => setState(() {}),
              );
            }),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addOpeningHour,
              icon: const Icon(Icons.add),
              label: const Text('Öffnungszeit hinzufügen'),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Notrufnummern'),
            if (_emergencyControllers.isEmpty)
              const Text('Keine Notrufnummern vorhanden.'),
            ..._emergencyControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: 'Notrufnummer',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Entfernen',
                      onPressed: () => _removeEmergencyNumber(index),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addEmergencyNumber,
              icon: const Icon(Icons.add),
              label: const Text('Notrufnummer hinzufügen'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Speichern...' : 'Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  void _addOpeningHour() {
    setState(() {
      _openingHoursEntries.add(_OpeningHoursEntry.empty());
    });
  }

  void _removeOpeningHour(int index) {
    setState(() {
      _openingHoursEntries.removeAt(index).dispose();
    });
  }

  void _addEmergencyNumber() {
    setState(() {
      _emergencyControllers.add(TextEditingController());
    });
  }

  void _removeEmergencyNumber(int index) {
    setState(() {
      _emergencyControllers.removeAt(index).dispose();
    });
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _saving = true);
    final config = TenantConfig(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      website: _websiteController.text.trim(),
      openingHours: _openingHoursEntries.map((entry) => entry.toModel()).toList(),
      emergencyNumbers: _emergencyControllers
          .map((controller) => controller.text.trim())
          .where((value) => value.isNotEmpty)
          .toList(),
    );

    try {
      final updated = await _tenantService.updateTenantConfig(
        config,
        adminKeyOverride: _adminKeyOverride,
      );
      if (_adminKeyOverride != null) {
        await _adminKeyStore.setAdminKey(
          AppConfig.tenantId,
          _adminKeyOverride!,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _handleInvalidAdminKey();
        return;
      }
      _showErrorMessage(_parseApiErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('Speichern fehlgeschlagen: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _handleInvalidAdminKey() async {
    if (_adminKeyOverride == null) {
      await _adminKeyStore.clearAdminKey(AppConfig.tenantId);
    }
    final newKey = await _promptAdminKey(
      title: 'Admin-Schlüssel falsch',
      actionLabel: 'Aktualisieren',
    );
    if (newKey != null) {
      setState(() => _adminKeyOverride = newKey);
      _showErrorMessage(
        'Admin-Schlüssel aktualisiert. Bitte erneut speichern.',
      );
    }
  }

  Future<String?> _promptAdminKey({
    required String title,
    required String actionLabel,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Admin-Schlüssel'),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              Navigator.of(context).pop(value);
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    return result;
  }

  String _parseApiErrorMessage(ApiException exception) {
    final message = exception.message;
    try {
      final decoded = jsonDecode(message);
      if (decoded is Map<String, dynamic>) {
        final directMessage = decoded['message'] ?? decoded['error'];
        if (directMessage is String && directMessage.isNotEmpty) {
          return directMessage;
        }
        final errors = decoded['errors'];
        if (errors is List) {
          return errors.map((error) => error.toString()).join(', ');
        }
        if (errors is Map) {
          return errors.entries
              .map((entry) => '${entry.key}: ${entry.value}')
              .join(', ');
        }
      }
    } catch (_) {
      // Ignore parse errors.
    }
    return message.isNotEmpty ? message : 'Unbekannter Fehler';
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _OpeningHoursEntry {
  _OpeningHoursEntry({
    required String day,
    required String opens,
    required String closes,
    required String note,
    required this.closed,
  })  : dayController = TextEditingController(text: day),
        opensController = TextEditingController(text: opens),
        closesController = TextEditingController(text: closes),
        noteController = TextEditingController(text: note);

  factory _OpeningHoursEntry.empty() {
    return _OpeningHoursEntry(
      day: '',
      opens: '',
      closes: '',
      note: '',
      closed: false,
    );
  }

  factory _OpeningHoursEntry.fromModel(TenantOpeningHour model) {
    return _OpeningHoursEntry(
      day: model.day,
      opens: model.opens,
      closes: model.closes,
      note: model.note,
      closed: model.closed,
    );
  }

  final TextEditingController dayController;
  final TextEditingController opensController;
  final TextEditingController closesController;
  final TextEditingController noteController;
  bool closed;

  void dispose() {
    dayController.dispose();
    opensController.dispose();
    closesController.dispose();
    noteController.dispose();
  }

  TenantOpeningHour toModel() {
    return TenantOpeningHour(
      day: dayController.text.trim(),
      opens: opensController.text.trim(),
      closes: closesController.text.trim(),
      closed: closed,
      note: noteController.text.trim(),
    );
  }
}

class _OpeningHoursCard extends StatelessWidget {
  const _OpeningHoursCard({
    required this.entry,
    required this.onRemove,
    required this.onChanged,
  });

  final _OpeningHoursEntry entry;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: entry.dayController,
                    decoration: const InputDecoration(labelText: 'Tag'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Tag ist erforderlich.';
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            SwitchListTile.adaptive(
              value: entry.closed,
              title: const Text('Geschlossen'),
              onChanged: (value) {
                entry.closed = value;
                onChanged();
              },
            ),
            if (!entry.closed) ...[
              TextFormField(
                controller: entry.opensController,
                decoration: const InputDecoration(labelText: 'Öffnet'),
                validator: (value) {
                  if (entry.closed) return null;
                  if (value == null || value.trim().isEmpty) {
                    return 'Öffnet-Zeit erforderlich.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: entry.closesController,
                decoration: const InputDecoration(labelText: 'Schließt'),
                validator: (value) {
                  if (entry.closed) return null;
                  if (value == null || value.trim().isEmpty) {
                    return 'Schließt-Zeit erforderlich.';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 8),
            TextFormField(
              controller: entry.noteController,
              decoration: const InputDecoration(labelText: 'Notiz'),
            ),
          ],
        ),
      ),
    );
  }
}
