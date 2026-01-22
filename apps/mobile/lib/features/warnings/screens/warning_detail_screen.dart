import 'package:flutter/material.dart';

import '../models/warning_item.dart';
import '../utils/warning_formatters.dart';

class WarningDetailScreen extends StatelessWidget {
  const WarningDetailScreen({
    super.key,
    required this.warning,
  });

  final WarningItem warning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Warnung')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            warning.title,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _severityIcon(warning.severity),
              const SizedBox(width: 8),
              Text(
                warning.severity.label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(
            label: 'Veröffentlicht',
            value: formatDateTime(warning.publishedAt),
          ),
          if (warning.validUntil != null)
            _InfoRow(
              label: 'Gültig bis',
              value: formatDateTime(warning.validUntil!),
            ),
          if (warning.source != null)
            _InfoRow(
              label: 'Quelle',
              value: warning.source!,
            ),
          const SizedBox(height: 16),
          Text(
            warning.body,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _severityIcon(WarningSeverity severity) {
    switch (severity) {
      case WarningSeverity.info:
        return const Icon(Icons.info_outline, color: Colors.blue);
      case WarningSeverity.warning:
        return const Icon(Icons.warning_amber, color: Colors.orange);
      case WarningSeverity.critical:
        return const Icon(Icons.report, color: Colors.red);
    }
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
