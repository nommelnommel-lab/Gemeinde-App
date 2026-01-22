import 'package:flutter/material.dart';

import '../../../shared/di/app_services_scope.dart';
import '../../../shared/navigation/app_router.dart';
import '../../events/models/event.dart';
import '../../events/models/event_permissions.dart';
import '../../events/screens/event_detail_screen.dart';
import '../../events/services/events_service.dart';
import '../../news/models/news_item.dart';
import '../../news/screens/news_detail_screen.dart';
import '../../news/services/news_service.dart';
import '../../warnings/models/warning_item.dart';
import '../../warnings/screens/warning_detail_screen.dart';
import '../../warnings/services/warnings_service.dart';
import '../../warnings/utils/warning_formatters.dart';

class StartFeedScreen extends StatefulWidget {
  const StartFeedScreen({
    super.key,
    required this.onSelectTab,
  });

  final ValueChanged<int> onSelectTab;

  @override
  State<StartFeedScreen> createState() => _StartFeedScreenState();
}

class _StartFeedScreenState extends State<StartFeedScreen> {
  late final EventsService _eventsService;
  late final NewsService _newsService;
  late final WarningsService _warningsService;
  bool _initialized = false;
  EventsPermissions _permissions =
      const EventsPermissions(canManageContent: false);

  bool _loading = true;
  String? _error;
  List<_AggregatedFeedItem> _items = const [];
  _FeedFilter _selectedFilter = _FeedFilter.all;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final services = AppServicesScope.of(context);
    _eventsService = services.eventsService;
    _newsService = services.newsService;
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
      final results = await Future.wait([
        _eventsService.getEvents(),
        _newsService.getNews(),
        _warningsService.getWarnings(),
        _eventsService.getPermissions(),
      ]);
      final events = results[0] as List<Event>;
      final news = results[1] as List<NewsItem>;
      final warnings = results[2] as List<WarningItem>;
      final permissions = results[3] as EventsPermissions;
      setState(() {
        _permissions = permissions;
        _items = _buildFeedItems(
          events: events,
          news: news,
          warnings: warnings,
        );
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
    final filteredItems = _filteredItems();

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
          Text(
            'Start Feed',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _FeedFilters(
            selected: _selectedFilter,
            onSelected: (filter) {
              setState(() => _selectedFilter = filter);
            },
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            _ErrorView(error: _error!, onRetry: _load)
          else if (filteredItems.isEmpty)
            const Text('Zurzeit sind keine passenden Beiträge verfügbar.')
          else
            ...filteredItems.map(
              (item) => _FeedListTile(
                item: item,
                formattedDate: _formatDate(item.date),
                onTap: () => _handleTap(item),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return formatDate(date);
  }

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

  void _handleTap(_AggregatedFeedItem item) {
    switch (item.type) {
      case _FeedItemType.event:
        if (item.event == null) return;
        AppRouterScope.of(context).push(
          EventDetailScreen(
            event: item.event!,
            eventsService: _eventsService,
            permissions: _permissions,
          ),
        );
        return;
      case _FeedItemType.news:
        if (item.news == null) return;
        AppRouterScope.of(context).push(
          NewsDetailScreen(item: item.news!, newsService: _newsService),
        );
        return;
      case _FeedItemType.warning:
        if (item.warning == null) return;
        AppRouterScope.of(context).push(
          WarningDetailScreen(
            warning: item.warning!,
            warningsService: _warningsService,
          ),
        );
        return;
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

enum _FeedFilter {
  all,
  events,
  news,
  warnings,
}

enum _FeedItemType {
  event,
  news,
  warning,
}

class _AggregatedFeedItem {
  const _AggregatedFeedItem({
    required this.type,
    required this.title,
    required this.date,
    this.event,
    this.news,
    this.warning,
  });

  final _FeedItemType type;
  final String title;
  final DateTime date;
  final Event? event;
  final NewsItem? news;
  final WarningItem? warning;
}

class _FeedFilters extends StatelessWidget {
  const _FeedFilters({
    required this.selected,
    required this.onSelected,
  });

  final _FeedFilter selected;
  final ValueChanged<_FeedFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final labels = <_FeedFilter, String>{
      _FeedFilter.all: 'Alle',
      _FeedFilter.events: 'Events',
      _FeedFilter.news: 'News',
      _FeedFilter.warnings: 'Warnungen',
    };

    return Wrap(
      spacing: 8,
      children: _FeedFilter.values.map((filter) {
        return ChoiceChip(
          label: Text(labels[filter]!),
          selected: filter == selected,
          onSelected: (_) => onSelected(filter),
        );
      }).toList(),
    );
  }
}

class _FeedListTile extends StatelessWidget {
  const _FeedListTile({
    required this.item,
    required this.formattedDate,
    required this.onTap,
  });

  final _AggregatedFeedItem item;
  final String formattedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: Icon(_iconForType(item.type)),
        title: Text(item.title),
        subtitle: Text(
          '${_labelForType(item.type)} · $formattedDate',
          style: theme.textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  IconData _iconForType(_FeedItemType type) {
    switch (type) {
      case _FeedItemType.event:
        return Icons.event;
      case _FeedItemType.news:
        return Icons.newspaper;
      case _FeedItemType.warning:
        return Icons.warning_amber;
    }
  }

  String _labelForType(_FeedItemType type) {
    switch (type) {
      case _FeedItemType.event:
        return 'Event';
      case _FeedItemType.news:
        return 'News';
      case _FeedItemType.warning:
        return 'Warnung';
    }
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
