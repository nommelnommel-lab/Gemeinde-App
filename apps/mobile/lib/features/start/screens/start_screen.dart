import 'package:flutter/material.dart';

import '../../../shared/auth/app_permissions.dart';
import '../../../shared/auth/auth_scope.dart';
import '../../../shared/di/app_services_scope.dart';
import '../../../shared/navigation/app_router.dart';
import '../../../shared/tenant/tenant_settings_scope.dart';
import '../../../shared/widgets/app_banner.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../../../shared/widgets/app_states.dart';
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
import '../../auth/screens/login_screen.dart';
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
    final settingsStore = TenantSettingsScope.of(context);
    final showEvents = settingsStore.isFeatureEnabled('events');
    final showNews = settingsStore.isFeatureEnabled('posts');
    final showWarnings = settingsStore.isFeatureEnabled('warnings');
    final permissions =
        AppPermissionsScope.maybePermissionsOf(context) ?? AppPermissions.empty;
    final isTourist = permissions.role == 'TOURIST';
    final showGemeindeApp = showEvents ||
        showNews ||
        settingsStore.isFeatureEnabled('services') ||
        settingsStore.isFeatureEnabled('places') ||
        settingsStore.isFeatureEnabled('clubs');
    final showVerwaltung = settingsStore.isFeatureEnabled('services') ||
        settingsStore.isFeatureEnabled('places') ||
        settingsStore.isFeatureEnabled('waste');
    final resolvedGemeindeApp = isTourist ? false : showGemeindeApp;
    final resolvedVerwaltung = isTourist ? false : showVerwaltung;
    int nextIndex = 1;
    if (showWarnings) {
      nextIndex += 1;
    }
    final gemeindeAppIndex = resolvedGemeindeApp ? nextIndex++ : null;
    final verwaltungIndex = resolvedVerwaltung ? nextIndex++ : null;

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
    final criticalWarning = _criticalWarningItem();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppSectionHeader(
            title: 'Aktuelles',
            subtitle: 'Neuigkeiten, Events und Hinweise aus der Gemeinde.',
          ),
          if (criticalWarning != null) ...[
            AppBanner(
              title: criticalWarning.title,
              description: _previewText(criticalWarning.body),
              severity: AppBannerSeverity.critical,
              onTap: () => _handleTap(criticalWarning),
            ),
            const SizedBox(height: 12),
          ],
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
            const EmptyState(
              title: 'Keine aktuellen Beiträge',
              message: 'Zurzeit sind keine passenden Beiträge verfügbar.',
              icon: Icons.article_outlined,
            )
          else
            ...filteredItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FeedListTile(
                  item: item,
                  formattedDate: _formatDate(item.date),
                  onTap: () => _handleTap(item),
                ),
              ),
            ),
          const SizedBox(height: 24),
          if (resolvedGemeindeApp || resolvedVerwaltung)
            const AppSectionHeader(
              title: 'Gemeinde & Verwaltung',
              subtitle: 'Services, Formulare und Angebote entdecken.',
            ),
          if (resolvedGemeindeApp)
            _StartCard(
              title: 'GemeindeApp',
              subtitle: 'Angebote und Veranstaltungen entdecken',
              icon: Icons.groups,
              onTap: gemeindeAppIndex == null
                  ? null
                  : () => widget.onSelectTab(gemeindeAppIndex),
            ),
          if (resolvedGemeindeApp && resolvedVerwaltung)
            const SizedBox(height: 16),
          if (resolvedVerwaltung)
            _StartCard(
              title: 'Verwaltung',
              subtitle: 'Formulare und Infos aus der Gemeinde',
              icon: Icons.admin_panel_settings,
              onTap: verwaltungIndex == null
                  ? null
                  : () => widget.onSelectTab(verwaltungIndex),
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

  String _previewText(String body) {
    const maxLength = 80;
    final cleaned = body.trim();
    if (cleaned.length <= maxLength) {
      return cleaned;
    }
    return '${cleaned.substring(0, maxLength)}…';
  }

  _FeedItem? _criticalWarningItem() {
    for (final item in _items) {
      if (item.type == _FeedItemType.warning &&
          item.warning?.severity == WarningSeverity.critical) {
        return item;
      }
    }
    return null;
  }

  Future<void> _handleTap(_FeedItem item) async {
    final permissions =
        AppPermissionsScope.maybePermissionsOf(context) ?? AppPermissions.empty;
    final isAuthenticated = AuthScope.of(context).isAuthenticated;
    final canEdit = isAuthenticated &&
        (permissions.canCreate.officialEvents ||
            permissions.canCreate.officialNews ||
            permissions.canCreate.officialWarnings);
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
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
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

    return SegmentedButton<_FeedFilter>(
      segments: filters
          .map(
            (filter) => ButtonSegment<_FeedFilter>(
              value: filter,
              label: Text(_labelForFilter(filter)),
            ),
          )
          .toList(),
      selected: <_FeedFilter>{selected},
      onSelectionChanged: (selection) {
        if (selection.isNotEmpty) {
          onSelected(selection.first);
        }
      },
    );
  }

  String _labelForFilter(_FeedFilter filter) {
    switch (filter) {
      case _FeedFilter.all:
        return 'Aktuelles';
      case _FeedFilter.events:
        return 'Events';
      case _FeedFilter.news:
        return 'News';
      case _FeedFilter.warnings:
        return 'Hinweise';
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
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconForType(item.type),
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.isEmpty
                          ? _fallbackTitle(item.type)
                          : item.title,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _detailLine(item),
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppChip(
                label: _labelForType(item.type),
                icon: _iconForType(item.type),
              ),
              AppChip(
                label: formattedDate,
                icon: Icons.calendar_today_outlined,
              ),
              if (item.type == _FeedItemType.event && item.location != null)
                AppChip(
                  label: _displayLocation(item.location ?? ''),
                  icon: Icons.place_outlined,
                ),
            ],
          ),
        ],
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
    final normalized = error.toLowerCase();
    final isAuthError = normalized.contains('http 401') ||
        normalized.contains('http 403') ||
        normalized.contains('sitzung abgelaufen');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AppCard(
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
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Erneut versuchen'),
                  ),
                  if (isAuthError)
                    OutlinedButton(
                      onPressed: () {
                        AppRouterScope.of(context).push(const LoginScreen());
                      },
                      child: const Text('Anmelden'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
