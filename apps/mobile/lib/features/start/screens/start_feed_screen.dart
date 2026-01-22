import 'package:flutter/material.dart';

import '../../../shared/auth/app_permissions.dart';
import '../../../shared/di/app_services_scope.dart';
import '../../../shared/navigation/app_router.dart';
import '../../../shared/widgets/coming_soon_content.dart';
import '../../events/models/event.dart';
import '../../events/screens/event_detail_screen.dart';
import '../../events/services/events_service.dart';
import '../../warnings/models/warning_item.dart';
import '../../warnings/screens/warning_detail_screen.dart';
import '../../warnings/screens/warnings_screen.dart';
import '../../warnings/services/warnings_service.dart';
import '../../warnings/utils/warning_formatters.dart';
import '../../warnings/utils/warning_widgets.dart';
import '../models/feed_item.dart';
import '../widgets/feed_card.dart';

class StartFeedScreen extends StatefulWidget {
  const StartFeedScreen({
    super.key,
  });

  @override
  State<StartFeedScreen> createState() => _StartFeedScreenState();
}

class _StartFeedScreenState extends State<StartFeedScreen> {
  late final EventsService _eventsService;
  late final WarningsService _warningsService;
  bool _initialized = false;
  bool _loading = true;
  String? _error;
  List<FeedItem> _items = const [];
  List<WarningItem> _warnings = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final services = AppServicesScope.of(context);
    _eventsService = services.eventsService;
    _warningsService = services.warningsService;
    _initialized = true;
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
      final items = _buildFeedItems(events);
      setState(() {
        _items = items;
        _warnings = warnings;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  List<FeedItem> _buildFeedItems(List<Event> events) {
    final now = DateTime.now();
    final items = [
      ...events.map(
        (event) => FeedItem(
          type: FeedItemType.event,
          title: event.title,
          body: event.description,
          date: event.date,
          location: event.location,
          event: event,
        ),
      ),
      FeedItem(
        type: FeedItemType.meetup,
        title: 'Nachbarschaftstreff im Rathausgarten',
        body: 'Gemeinsam kennenlernen, austauschen und neue Kontakte knüpfen.',
        date: now.add(const Duration(days: 3, hours: 18)),
        location: 'Rathausgarten',
      ),
      FeedItem(
        type: FeedItemType.news,
        title: 'Neuer Spielplatz eröffnet',
        body: 'Die Gemeinde eröffnet einen neuen Spielplatz für Familien.',
        date: now.add(const Duration(days: 1)),
      ),
      FeedItem(
        type: FeedItemType.meetup,
        title: 'Seniorencafé am Sonntag',
        body: 'Kaffee, Kuchen und Musik für Seniorinnen und Senioren.',
        date: now.add(const Duration(days: 5, hours: 15)),
        location: 'Gemeindezentrum',
      ),
      FeedItem(
        type: FeedItemType.news,
        title: 'Sommerferienprogramm ist da',
        body: 'Jetzt Programm für Kinder und Jugendliche entdecken.',
        date: now.add(const Duration(days: 7)),
      ),
    ];

    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorView(error: _error!, onRetry: _load);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: _items.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('Aktuell sind keine Beiträge verfügbar.')),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _WarningsSection(
                    warnings:
                        _sortedWarnings(_activeWarnings(_warnings)).take(2).toList(),
                    onShowAll: () => AppRouterScope.of(context).push(
                      const WarningsScreen(),
                    ),
                    onSelectWarning: (warning) =>
                        AppRouterScope.of(context).push(
                      WarningDetailScreen(
                        warning: warning,
                        warningsService: _warningsService,
                        canEdit:
                            AppPermissionsScope.maybePermissionsOf(context)
                                    ?.canManageContent ??
                                false,
                      ),
                    ),
                  );
                }

                final item = _items[index - 1];
                return FeedCard(
                  item: item,
                  icon: _iconForType(item.type),
                  label: _labelForType(item.type),
                  formattedDate: _formatDate(item.date),
                  onTap: () => _handleTap(item),
                );
              },
            ),
    );
  }

  void _handleTap(FeedItem item) {
    if (item.type == FeedItemType.event && item.event != null) {
      final canEdit =
          AppPermissionsScope.maybePermissionsOf(context)?.canManageContent ??
              false;
      AppRouterScope.of(context).push(
        EventDetailScreen(
          event: item.event!,
          eventsService: _eventsService,
          canEdit: canEdit,
        ),
      );
      return;
    }

    final description = _comingSoonDescription(item.type);
    AppRouterScope.of(context).push(
      ComingSoonScreen(title: item.title, description: description),
    );
  }

  String _formatDate(DateTime date) {
    return formatDate(date);
  }

  IconData _iconForType(FeedItemType type) {
    switch (type) {
      case FeedItemType.event:
        return Icons.event;
      case FeedItemType.meetup:
        return Icons.people_alt;
      case FeedItemType.warning:
        return Icons.warning_amber;
      case FeedItemType.news:
        return Icons.newspaper;
    }
  }

  String _labelForType(FeedItemType type) {
    switch (type) {
      case FeedItemType.event:
        return 'Event';
      case FeedItemType.meetup:
        return 'Treffpunkt';
      case FeedItemType.warning:
        return 'Warnung';
      case FeedItemType.news:
        return 'News';
    }
  }

  String _comingSoonDescription(FeedItemType type) {
    switch (type) {
      case FeedItemType.meetup:
        return 'Hier findest du künftig alle Nachbarschaftstreffen in der Gemeinde.';
      case FeedItemType.warning:
        return 'Warnmeldungen werden bald zentral hier gesammelt angezeigt.';
      case FeedItemType.news:
        return 'News und aktuelle Meldungen werden hier demnächst verfügbar sein.';
      case FeedItemType.event:
        return 'Weitere Informationen folgen.';
    }
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
          b.value.publishedAt.compareTo(a.value.publishedAt);
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
                    Text(formatDateTime(warning.publishedAt)),
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Feed konnte nicht geladen werden',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ComingSoonContent(description: description),
    );
  }
}
