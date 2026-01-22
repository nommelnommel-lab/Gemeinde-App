import 'package:flutter/material.dart';

import '../../../shared/navigation/app_router.dart';
import '../models/warning_item.dart';
import '../services/warnings_service.dart';
import '../utils/warning_formatters.dart';
import '../utils/warning_widgets.dart';
import 'warning_form_screen.dart';

class WarningDetailScreen extends StatefulWidget {
  const WarningDetailScreen({
    super.key,
    required this.warning,
    required this.warningsService,
    this.isAdmin = false,
  });

  final WarningItem warning;
  final WarningsService warningsService;
  final bool isAdmin;

  @override
  State<WarningDetailScreen> createState() => _WarningDetailScreenState();
}

class _WarningDetailScreenState extends State<WarningDetailScreen> {
  late WarningItem _warning;

  @override
  void initState() {
    super.initState();
    _warning = widget.warning;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warnung'),
        actions: widget.isAdmin
            ? [
                IconButton(
                  onPressed: _handleEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Warnung bearbeiten',
                ),
                IconButton(
                  onPressed: _handleDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Warnung löschen',
                ),
              ]
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _warning.title,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          WarningSeverityChip(severity: _warning.severity),
          const SizedBox(height: 16),
          _InfoRow(
            label: 'Erstellt',
            value: formatDateTime(_warning.createdAt),
          ),
          if (_warning.validUntil != null)
            _InfoRow(
              label: 'Gültig bis',
              value: formatDateTime(_warning.validUntil!),
            ),
          if (_warning.source != null)
            _InfoRow(
              label: 'Quelle',
              value: _warning.source!,
            ),
          const SizedBox(height: 16),
          Text(
            _warning.body,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Future<void> _handleEdit() async {
    final updated = await AppRouterScope.of(context).push<WarningItem>(
      WarningFormScreen(
        warningsService: widget.warningsService,
        warning: _warning,
      ),
    );
    if (updated != null) {
      setState(() => _warning = updated);
    }
  }

  Future<void> _handleDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Warnung löschen'),
        content: const Text('Soll diese Warnung wirklich gelöscht werden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) {
      return;
    }
    await widget.warningsService.deleteWarning(_warning.id);
    AppRouterScope.of(context).pop(true);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
