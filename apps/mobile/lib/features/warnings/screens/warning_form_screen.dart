import 'package:flutter/material.dart';

import '../models/warning_item.dart';
import '../services/warnings_service.dart';
import '../utils/warning_formatters.dart';

class WarningFormScreen extends StatefulWidget {
  const WarningFormScreen({
    super.key,
    required this.warningsService,
    this.warning,
  });

  final WarningsService warningsService;
  final WarningItem? warning;

  @override
  State<WarningFormScreen> createState() => _WarningFormScreenState();
}

class _WarningFormScreenState extends State<WarningFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  WarningSeverity _severity = WarningSeverity.info;
  DateTime? _validUntil;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.warning?.title ?? '');
    _bodyController = TextEditingController(text: widget.warning?.body ?? '');
    _severity = widget.warning?.severity ?? WarningSeverity.info;
    _validUntil = widget.warning?.validUntil;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.warning != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Warnung bearbeiten' : 'Warnung erstellen'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titel',
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte einen Titel eingeben.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte eine Beschreibung eingeben.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<WarningSeverity>(
              value: _severity,
              decoration: const InputDecoration(
                labelText: 'Schweregrad',
              ),
              items: WarningSeverity.values
                  .map(
                    (severity) => DropdownMenuItem(
                      value: severity,
                      child: Text(severity.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _severity = value);
                }
              },
            ),
            const SizedBox(height: 16),
            _ValidUntilPicker(
              validUntil: _validUntil,
              onPick: _handlePickValidUntil,
              onClear: _validUntil == null
                  ? null
                  : () => setState(() => _validUntil = null),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _handleSave,
              child: Text(isEditing ? 'Änderungen speichern' : 'Warnung speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final warning = widget.warning;
      WarningItem saved;
      if (warning == null) {
        saved = await widget.warningsService.createWarning(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          severity: _severity,
          validUntil: _validUntil,
        );
      } else {
        saved = await widget.warningsService.updateWarning(
          WarningItem(
            id: warning.id,
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
            severity: _severity,
            createdAt: warning.createdAt,
            validUntil: _validUntil,
            source: warning.source,
          ),
        );
      }
      if (mounted) {
        Navigator.of(context).pop(saved);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speichern fehlgeschlagen: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _handlePickValidUntil() async {
    final now = DateTime.now();
    final initialDate = _validUntil ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) {
      return;
    }
    setState(() {
      _validUntil = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }
}

class _ValidUntilPicker extends StatelessWidget {
  const _ValidUntilPicker({
    required this.validUntil,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? validUntil;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Gültig bis (optional)',
        border: OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              validUntil == null
                  ? 'Keine Angabe'
                  : formatDateTime(validUntil!),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onPick,
            child: const Text('Auswählen'),
          ),
          if (onClear != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.clear),
              tooltip: 'Datum entfernen',
            ),
          ],
        ],
      ),
    );
  }
}
