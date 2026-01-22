import 'package:flutter/material.dart';

import '../../../shared/navigation/app_router.dart';
import '../../events/models/event.dart';
import '../../events/services/events_service.dart';
import '../../warnings/models/warning_item.dart';
import '../../warnings/screens/warning_detail_screen.dart';
import '../../warnings/screens/warnings_screen.dart';
import '../../warnings/services/warnings_service.dart';
import '../../warnings/utils/warning_formatters.dart';
import '../../warnings/utils/warning_widgets.dart';

class StartFeedScreen extends StatefulWidget {
  const StartFeedScreen({
    super.key,
    required this.onSelectTab,
    required this.eventsService,
    required this.warningsService,
  });

  final ValueChanged<int> onSelectTab;
  final EventsService eventsService;
  final WarningsService warningsService;

  @override
  State<StartFeedScreen> createState() => _StartFeedScreenState();
}

class _StartFeedScreenState extends State<StartFeedScreen> {
  late final EventsService _eventsService;
  late final WarningsService _warningsService;

  bool _loading = true;
  String? _error;
  List<Event> _events = const [];
  List<WarningItem> _warnings = const [];

  @override
  void initState() {
    super.initState();
    _eventsService = widget.eventsService;
    _warningsService = widget.warningsService;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final events = await _eventsService.getEvents();
      final warnings = await _warningsService.getWarnings();
      setState(() {
        _events = events;
        _warnings = warnings;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StartCard(
            title: 'GemeindeApp',
            subtitle: 'Angebote und Veranstaltungen entdecken',
            icon: Icons.groups,
            onTap: () => widget.onSelectTab(2),
          ),
          const SizedBox(height: 16),
          _StartCard(
            title: 'Verwaltung',
            subtitle: 'Formulare und Infos aus der Gemeinde',
            icon: Icons.admin_panel_settings,
            onTap: () => widget.onSelectTab(3),
          ),
          const SizedBox(height: 24),
          _WarningsSection(
            warnings: _sortedWarnings(_activeWarnings(_warnings)).take(2).toList(),
            onShowAll: () => AppRouterScope.of(context).push(
              WarningsScreen(warningsService: _warningsService),
            ),
            onSelectWarning: (warning) => AppRouterScope.of(context).push(
              WarningDetailScreen(
                warning: warning,
                warningsService: _warningsService,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nächste Events',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            _EventsErrorView(error: _error!, onRetry: _load)
          else if (_events.isEmpty)
            const Text('Zurzeit sind keine Veranstaltungen geplant.')
          else
            ..._events.take(3).map(
                  (event) => Card(
                    child: ListTile(
                      title: Text(event.title),
                      subtitle:
                          Text('${_formatDate(event.date)} · ${event.location}'),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return formatDate(date);
  }

  List<WarningItem> _sortedWarnings(List<WarningItem> warnings) {
    final indexed = warnings.asMap().entries.toList();
    indexed.sort((a, b) {
      final severityCompare =
          _severityRank(a.value.severity).compareTo(
        _severityRank(b.value.severity),
      );
      if (severityCompare != 0) {
        return severityCompare;
      }
      final dateCompare =
          b.value.createdAt.compareTo(a.value.createdAt);
      if (dateCompare != 0) {
        return dateCompare;
      }
      return a.key.compareTo(b.key);
    });
    return indexed.map((entry) => entry.value).toList();
  }

  List<WarningItem> _activeWarnings(List<WarningItem> warnings) {
    final now = DateTime.now();
    return warnings
        .where(
          (warning) =>
              warning.validUntil == null ||
              warning.validUntil!.isAfter(now),
        )
        .toList();
  }

  int _severityRank(WarningSeverity severity) {
    switch (severity) {
      case WarningSeverity.critical:
        return 0;
      case WarningSeverity.warning:
        return 1;
      case WarningSeverity.info:
        return 2;
    }
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                child: Icon(icon, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventsErrorView extends StatelessWidget {
  const _EventsErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Events konnten nicht geladen werden.'),
        const SizedBox(height: 8),
        Text(
          error,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        TextButton(
          onPressed: onRetry,
          child: const Text('Erneut versuchen'),
        ),
      ],
    );
  }
}

class _WarningsSection extends StatelessWidget {
  const _WarningsSection({
    required this.warnings,
    required this.onShowAll,
    required this.onSelectWarning,
  });

  final List<WarningItem> warnings;
  final VoidCallback onShowAll;
  final ValueChanged<WarningItem> onSelectWarning;

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Aktuell gibt es keine Warnungen.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Warnungen',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: onShowAll,
                  child: const Text('Alle anzeigen'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...warnings.map(
              (warning) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(warning.title),
                subtitle: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    WarningSeverityChip(severity: warning.severity),
                    Text(formatDateTime(warning.createdAt)),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onSelectWarning(warning),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
