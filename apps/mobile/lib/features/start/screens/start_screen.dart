import 'package:flutter/material.dart';

import '../../../shared/auth/app_permissions.dart';
import '../../../shared/di/app_services_scope.dart';
import '../../../shared/navigation/app_router.dart';
import '../../../shared/tenant/tenant_settings_scope.dart';
import '../../events/models/event.dart';
import '../../events/screens/event_detail_screen.dart';
import '../../events/services/events_service.dart';
import '../../news/models/news_item.dart';
import '../../news/screens/news_detail_screen.dart';
import '../../news/services/news_service.dart';
import '../../warnings/models/warning_item.dart';
import '../../warnings/screens/warning_detail_screen.dart';
import '../../warnings/services/warnings_service.dart';
import '../../warnings/utils/warning_formatters.dart';
import '../services/feed_service.dart';

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
  late final FeedService _feedService;
  late final NewsService _newsService;
  late final WarningsService _warningsService;
  bool _initialized = false;

  bool _loading = true;
  String? _error;
  List<_FeedItem> _items = const [];
  _FeedFilter _selectedFilter = _FeedFilter.all;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final services = AppServicesScope.of(context);
    _eventsService = services.eventsService;
    _feedService = services.feedService;
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
      final feedSnapshot = await _feedService.getFeed();
      final settingsStore = TenantSettingsScope.of(context);
      final showEvents = settingsStore.isFeatureEnabled('events');
      final showNews = settingsStore.isFeatureEnabled('posts');
      final showWarnings = settingsStore.isFeatureEnabled('warnings');
      if (!mounted) return;
      setState(() {
        _items = _buildFeedItems(
          events: feedSnapshot.events,
          news: feedSnapshot.news,
          warnings: feedSnapshot.warnings,
          showEvents: showEvents,
          showNews: showNews,
          showWarnings: showWarnings,
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
    final settingsStore = TenantSettingsScope.of(context);
    final showEvents = settingsStore.isFeatureEnabled('events');
    final showNews = settingsStore.isFeatureEnabled('posts');
    final showWarnings = settingsStore.isFeatureEnabled('warnings');
    final showGemeindeApp = showEvents ||
        showNews ||
        settingsStore.isFeatureEnabled('services') ||
        settingsStore.isFeatureEnabled('places') ||
        settingsStore.isFeatureEnabled('clubs');
    final showVerwaltung = settingsStore.isFeatureEnabled('services') ||
        settingsStore.isFeatureEnabled('places') ||
        settingsStore.isFeatureEnabled('waste');
    int nextIndex = 1;
    if (showWarnings) {
      nextIndex += 1;
    }
    final gemeindeAppIndex = showGemeindeApp ? nextIndex++ : null;
    final verwaltungIndex = showVerwaltung ? nextIndex++ : null;

    final resolvedFilter = _resolveFilter(
      showEvents: showEvents,
      showNews: showNews,
      showWarnings: showWarnings,
    );
    final filteredItems = _filteredItems(
      showEvents: showEvents,
      showNews: showNews,
      showWarnings: showWarnings,
      filter: resolvedFilter,
    );

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (showGemeindeApp)
            _StartCard(
              title: 'GemeindeApp',
              subtitle: 'Angebote und Veranstaltungen entdecken',
              icon: Icons.groups,
              onTap: gemeindeAppIndex == null
                  ? null
                  : () => widget.onSelectTab(gemeindeAppIndex),
            ),
          if (showGemeindeApp && showVerwaltung) const SizedBox(height: 16),
          if (showVerwaltung)
            _StartCard(
              title: 'Verwaltung',
              subtitle: 'Formulare und Infos aus der Gemeinde',
              icon: Icons.admin_panel_settings,
              onTap: verwaltungIndex == null
                  ? null
                  : () => widget.onSelectTab(verwaltungIndex),
            ),
          const SizedBox(height: 24),
          Text(
            'Nachbarschaft',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _FeedFilters(
            selected: resolvedFilter,
            availableFilters: _availableFilters(
              showEvents: showEvents,
              showNews: showNews,
              showWarnings: showWarnings,
            ),
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

  List<_FeedItem> _buildFeedItems({
    required List<Event> events,
    required List<NewsItem> news,
    required List<WarningItem> warnings,
    required bool showEvents,
    required bool showNews,
    required bool showWarnings,
  }) {
    final now = DateTime.now();
    final start = _startOfDay(now);
    final end = _endOfDay(now.add(const Duration(days: 28)));

    final upcomingEvents = showEvents
        ? events
            .where(
              (event) =>
                  !event.date.isBefore(start) && !event.date.isAfter(end),
            )
            .toList()
        : const <Event>[];

    final activeWarnings = showWarnings
        ? warnings
            .where(
              (warning) =>
                  warning.validUntil == null ||
                  warning.validUntil!.isAfter(now),
            )
            .toList()
        : const <WarningItem>[];

    final items = <_FeedItem>[
      ...upcomingEvents.map(
        (event) => _FeedItem(
          type: _FeedItemType.event,
          title: event.title,
          body: event.description,
          date: event.date,
          location: event.location,
          event: event,
        ),
      ),
      if (showNews)
        ...news.map(
          (item) => _FeedItem(
            type: _FeedItemType.news,
            title: item.title,
            body: item.summary,
            date: _newsDate(item),
            news: item,
          ),
        ),
      ...activeWarnings.map(
        (warning) => _FeedItem(
          type: _FeedItemType.warning,
          title: warning.title,
          body: warning.body,
          date: _warningDate(warning),
          warning: warning,
        ),
      ),
    ];

    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  List<_FeedItem> _filteredItems({
    required bool showEvents,
    required bool showNews,
    required bool showWarnings,
    required _FeedFilter filter,
  }) {
    switch (filter) {
      case _FeedFilter.all:
        return _items;
      case _FeedFilter.events:
        if (!showEvents) return const [];
        return _items
            .where((item) => item.type == _FeedItemType.event)
            .toList();
      case _FeedFilter.news:
        if (!showNews) return const [];
        return _items
            .where((item) => item.type == _FeedItemType.news)
            .toList();
      case _FeedFilter.warnings:
        if (!showWarnings) return const [];
        return _items
            .where((item) => item.type == _FeedItemType.warning)
            .toList();
    }
  }

  _FeedFilter _resolveFilter({
    required bool showEvents,
    required bool showNews,
    required bool showWarnings,
  }) {
    switch (_selectedFilter) {
      case _FeedFilter.events:
        return showEvents ? _selectedFilter : _FeedFilter.all;
      case _FeedFilter.news:
        return showNews ? _selectedFilter : _FeedFilter.all;
      case _FeedFilter.warnings:
        return showWarnings ? _selectedFilter : _FeedFilter.all;
      case _FeedFilter.all:
        return _selectedFilter;
    }
  }

  List<_FeedFilter> _availableFilters({
    required bool showEvents,
    required bool showNews,
    required bool showWarnings,
  }) {
    return [
      _FeedFilter.all,
      if (showEvents) _FeedFilter.events,
      if (showNews) _FeedFilter.news,
      if (showWarnings) _FeedFilter.warnings,
    ];
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  DateTime _newsDate(NewsItem item) {
    final DateTime? publishedAt = item.publishedAt;
    final DateTime? createdAt = item.createdAt;
    return publishedAt ?? createdAt ?? DateTime.now();
  }

  DateTime _warningDate(WarningItem warning) {
    final DateTime? createdAt = warning.createdAt;
    final DateTime? publishedAt = warning.publishedAt;
    return createdAt ?? publishedAt ?? DateTime.now();
  }

  Future<void> _handleTap(_FeedItem item) async {
    final permissions = AppPermissionsScope.maybePermissionsOf(context);
    bool canEdit;
    switch (item.type) {
      case _FeedItemType.event:
        canEdit = permissions?.canCreateEvents ?? false;
        break;
      case _FeedItemType.news:
        canEdit = permissions?.canCreateNews ?? false;
        break;
      case _FeedItemType.warning:
        canEdit = permissions?.canCreateWarnings ?? false;
        break;
    }
    switch (item.type) {
      case _FeedItemType.event:
        if (item.event == null) return;
        final result = await AppRouterScope.of(context).push(
          EventDetailScreen(
            event: item.event!,
            eventsService: _eventsService,
            canEdit: canEdit,
          ),
        );
        if (result == true) {
          await _load();
        }
        return;
      case _FeedItemType.news:
        if (item.news == null) return;
        final result = await AppRouterScope.of(context).push(
          NewsDetailScreen(
            item: item.news!,
            newsService: _newsService,
            canEdit: canEdit,
          ),
        );
        if (result == true) {
          await _load();
        }
        return;
      case _FeedItemType.warning:
        if (item.warning == null) return;
        final result = await AppRouterScope.of(context).push(
          WarningDetailScreen(
            warning: item.warning!,
            warningsService: _warningsService,
            canEdit: canEdit,
          ),
        );
        if (result == true) {
          await _load();
        }
        return;
    }
  }
}

class _FeedItem {
  const _FeedItem({
    required this.type,
    required this.title,
    required this.body,
    required this.date,
    this.location,
    this.event,
    this.news,
    this.warning,
  });

  final _FeedItemType type;
  final String title;
  final String body;
  final DateTime date;
  final String? location;
  final Event? event;
  final NewsItem? news;
  final WarningItem? warning;
}

enum _FeedItemType {
  event,
  news,
  warning,
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
  final VoidCallback? onTap;

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

class _FeedFilters extends StatelessWidget {
  const _FeedFilters({
    required this.selected,
    required this.availableFilters,
    required this.onSelected,
  });

  final _FeedFilter selected;
  final List<_FeedFilter> availableFilters;
  final ValueChanged<_FeedFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final filters = availableFilters;

    return Wrap(
      spacing: 8,
      children: filters.map((filter) {
        final label = _labelForFilter(filter);
        return ChoiceChip(
          label: Text(label),
          selected: filter == selected,
          onSelected: (_) => onSelected(filter),
        );
      }).toList(),
    );
  }

  String _labelForFilter(_FeedFilter filter) {
    switch (filter) {
      case _FeedFilter.all:
        return 'Alle';
      case _FeedFilter.events:
        return 'Events';
      case _FeedFilter.news:
        return 'News';
      case _FeedFilter.warnings:
        return 'Warnungen';
    }
  }
}

class _FeedListTile extends StatelessWidget {
  const _FeedListTile({
    required this.item,
    required this.formattedDate,
    required this.onTap,
  });

  final _FeedItem item;
  final String formattedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: Icon(_iconForType(item.type)),
        title: Text(item.title.isEmpty ? _fallbackTitle(item.type) : item.title),
        subtitle: Text(
          _subtitle(item, formattedDate),
          style: theme.textTheme.bodySmall,
        ),
        isThreeLine: true,
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

  String _fallbackTitle(_FeedItemType type) {
    switch (type) {
      case _FeedItemType.event:
        return 'Event';
      case _FeedItemType.news:
        return 'News';
      case _FeedItemType.warning:
        return 'Warnung';
    }
  }

  String _subtitle(_FeedItem item, String formattedDate) {
    final label = _labelForType(item.type);
    final detail = _detailLine(item);
    if (detail.isEmpty) {
      return '$label · $formattedDate';
    }
    return '$label · $formattedDate\n$detail';
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

  String _detailLine(_FeedItem item) {
    switch (item.type) {
      case _FeedItemType.event:
        return _displayLocation(item.location ?? '');
      case _FeedItemType.news:
      case _FeedItemType.warning:
        return _preview(item.body);
    }
  }

  String _displayLocation(String location) {
    final trimmed = location.trim();
    return trimmed.isEmpty ? 'Ort wird noch bekannt gegeben' : trimmed;
  }

  String _preview(String body) {
    const maxLength = 60;
    final cleaned = body.trim();
    if (cleaned.length <= maxLength) {
      return cleaned;
    }
    return '${cleaned.substring(0, maxLength)}…';
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
