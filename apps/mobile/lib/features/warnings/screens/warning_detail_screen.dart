import 'package:flutter/material.dart';

import '../../../shared/navigation/app_router.dart';
import '../../../shared/widgets/app_banner.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../models/warning_item.dart';
import '../services/warnings_service.dart';
import '../utils/warning_formatters.dart';
import 'warning_form_screen.dart';

class WarningDetailScreen extends StatefulWidget {
  const WarningDetailScreen({
    super.key,
    required this.warning,
    required this.warningsService,
    required this.canEdit,
  });

  final WarningItem warning;
  final WarningsService warningsService;
  final bool canEdit;

  @override
  State<WarningDetailScreen> createState() => _WarningDetailScreenState();
}

class _WarningDetailScreenState extends State<WarningDetailScreen> {
  late WarningItem _warning;
  bool _deleting = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _warning = widget.warning;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: _handleWillPop,
      child: AppScaffold(
        appBar: AppBar(
          title: const Text('Warnung'),
          actions: widget.canEdit
              ? [
                  IconButton(
                    tooltip: 'Bearbeiten',
                    icon: const Icon(Icons.edit),
                    onPressed: _deleting ? null : _editWarning,
                  ),
                  IconButton(
                    tooltip: 'Löschen',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _deleting ? null : _confirmDelete,
                  ),
                ]
              : null,
        ),
        padBody: false,
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppSectionHeader(
              title: _warning.title,
              subtitle: formatDateTime(_warning.publishedAt),
            ),
            const SizedBox(height: 8),
            AppBanner(
              title: _warning.severity.label,
              description: _warning.source ?? 'Hinweis aus der Gemeinde',
              severity: _bannerSeverity(_warning.severity),
            ),
            const SizedBox(height: 16),
            AppSectionHeader(title: 'Details'),
            AppCard(
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Veröffentlicht',
                    value: formatDateTime(_warning.publishedAt),
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
                ],
              ),
            ),
            const SizedBox(height: 16),
            const AppSectionHeader(title: 'Hinweistext'),
            AppCard(
              child: Text(
                _warning.body,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBannerSeverity _bannerSeverity(WarningSeverity severity) {
    switch (severity) {
      case WarningSeverity.info:
        return AppBannerSeverity.info;
      case WarningSeverity.warning:
        return AppBannerSeverity.warning;
      case WarningSeverity.critical:
        return AppBannerSeverity.critical;
    }
  }

  Future<void> _editWarning() async {
    final updated = await AppRouterScope.of(context).push<WarningItem>(
      WarningFormScreen(
        warningsService: widget.warningsService,
        warning: _warning,
      ),
    );
    if (!mounted || updated == null) return;
    setState(() {
      _warning = updated;
      _hasChanges = true;
    });
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Warnung löschen?'),
          content: const Text(
            'Möchtest du diese Warnung wirklich löschen? Dieser Schritt kann nicht rückgängig gemacht werden.',
          ),
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
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await widget.warningsService.deleteWarning(_warning.id);
      if (!mounted) return;
      AppRouterScope.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Löschen fehlgeschlagen: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  Future<bool> _handleWillPop() async {
    AppRouterScope.of(context).pop(_hasChanges);
    return false;
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
