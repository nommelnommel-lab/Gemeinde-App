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
import '../../citizen_posts/models/citizen_post.dart';
import '../../citizen_posts/screens/citizen_posts_list_screen.dart';
import '../../citizen_posts/services/citizen_posts_service.dart';
import '../../events/models/event.dart';
import '../../events/screens/events_screen.dart';
import '../../events/screens/event_detail_screen.dart';
import '../../events/services/events_service.dart';
import '../../news/models/news_item.dart';
import '../../news/screens/news_screen.dart';
import '../../news/screens/news_detail_screen.dart';
import '../../news/services/news_service.dart';
import '../../gemeinde_app/screens/category_sub_hub_screen.dart';
import '../../warnings/models/warning_item.dart';
import '../../warnings/screens/warning_detail_screen.dart';
import '../../warnings/services/warnings_service.dart';
import '../../warnings/utils/warning_formatters.dart';
import '../../auth/screens/login_screen.dart';

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
  late final CitizenPostsService _citizenPostsService;
  bool _initialized = false;

  bool _loading = true;
  String? _error;
  List<Event> _events = const [];
  List<NewsItem> _news = const [];
  List<WarningItem> _warnings = const [];
  Map<_CitizenTeaserType, _CitizenTeaserState> _citizenTeasers = const {};
  String? _eventsError;
  String? _newsError;

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
    _citizenPostsService = services.citizenPostsService;
    _initialized = true;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _eventsError = null;
      _newsError = null;
    });

    try {
      final settingsStore = TenantSettingsScope.of(context);
      final showEvents = settingsStore.isFeatureEnabled('events');
      final showNews = settingsStore.isFeatureEnabled('posts');
      final showWarnings = settingsStore.isFeatureEnabled('warnings');
      final showServices = settingsStore.isFeatureEnabled('services');
      final showCafeMeetups = settingsStore.isFeatureEnabled('places');
      final showKidsMeetups = settingsStore.isFeatureEnabled('clubs');

      final eventsResult = await _safeLoad(
        () => showEvents
            ? _eventsService.getEvents()
            : Future.value(<Event>[]),
        errorMessage: 'Events konnten nicht geladen werden.',
      );
      final newsResult = await _safeLoad(
        () => showNews ? _newsService.getNews() : Future.value(<NewsItem>[]),
        errorMessage: 'News konnten nicht geladen werden.',
      );
      final warningsResult = await _safeLoad(
        () => showWarnings
            ? _warningsService.getWarnings()
            : Future.value(<WarningItem>[]),
        errorMessage: 'Warnungen konnten nicht geladen werden.',
      );
      final citizenTeasers = showServices || showCafeMeetups || showKidsMeetups
          ? await _loadCitizenTeasers(
              showServices: showServices,
              showCafeMeetups: showCafeMeetups,
              showKidsMeetups: showKidsMeetups,
            )
          : const <_CitizenTeaserType, _CitizenTeaserState>{};

      if (!mounted) return;
      setState(() {
        _events = eventsResult.items;
        _news = newsResult.items;
        _warnings = warningsResult.items;
        _eventsError = eventsResult.error;
        _newsError = newsResult.error;
        _citizenTeasers = citizenTeasers;
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
    final showServices = settingsStore.isFeatureEnabled('services');
    final showCafeMeetups = settingsStore.isFeatureEnabled('places');
    final showKidsMeetups = settingsStore.isFeatureEnabled('clubs');
    final warningItems = _buildWarningItems();
    final eventItems = _buildEventItems();
    final newsItems = _buildNewsItems();
    final criticalWarning = _criticalWarningItem(warningItems);
    final citizenTeasers = _availableCitizenTeasers(
      showServices: showServices,
      showCafeMeetups: showCafeMeetups,
      showKidsMeetups: showKidsMeetups,
    );

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
          if (_loading)
            ..._buildLoadingSections(
              showWarnings: showWarnings,
              showEvents: showEvents,
              showNews: showNews,
              citizenTeasers: citizenTeasers,
            )
          else if (_error != null)
            _ErrorView(error: _error!, onRetry: _load)
          else ...[
            if (showWarnings) ..._buildWarningsSection(warningItems),
            if (showEvents)
              ..._buildEventsSection(
                eventItems,
                error: _eventsError,
              ),
            if (showNews)
              ..._buildNewsSection(
                newsItems,
                error: _newsError,
              ),
            if (citizenTeasers.isNotEmpty)
              ..._buildCitizenTeasersSection(
                citizenTeasers,
              ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return formatDate(date);
  }

  List<_FeedItem> _buildWarningItems() {
    final now = DateTime.now();
    final warnings = _warnings
        .where(
          (warning) =>
              warning.validUntil == null ||
              warning.validUntil!.isAfter(now),
        )
        .toList()
      ..sort((a, b) => _warningDate(b).compareTo(_warningDate(a)));

    return warnings
        .take(3)
        .map(
          (warning) => _FeedItem(
            type: _FeedItemType.warning,
            title: warning.title,
            body: warning.body,
            date: _warningDate(warning),
            warning: warning,
          ),
        )
        .toList();
  }

  List<_FeedItem> _buildEventItems() {
    final now = DateTime.now();
    final start = _startOfDay(now);
    final end = _endOfDay(now.add(const Duration(days: 28)));

    final upcomingEvents = _events
        .where(
          (event) => !event.date.isBefore(start) && !event.date.isAfter(end),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return upcomingEvents
        .take(5)
        .map(
          (event) => _FeedItem(
            type: _FeedItemType.event,
            title: event.title,
            body: event.description,
            date: event.date,
            location: event.location,
            event: event,
          ),
        )
        .toList();
  }

  List<_FeedItem> _buildNewsItems() {
    final sortedNews = [..._news]
      ..sort((a, b) => _newsDate(b).compareTo(_newsDate(a)));

    return sortedNews
        .take(5)
        .map(
          (item) => _FeedItem(
            type: _FeedItemType.news,
            title: item.title,
            body: item.summary,
            date: _newsDate(item),
            news: item,
          ),
        )
        .toList();
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

  _FeedItem? _criticalWarningItem(List<_FeedItem> warnings) {
    for (final item in warnings) {
      if (item.warning?.severity == WarningSeverity.critical) {
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

  Future<_SectionResult<T>> _safeLoad<T>(
    Future<List<T>> Function() loader, {
    required String errorMessage,
  }) async {
    try {
      final items = await loader();
      return _SectionResult(items: items);
    } catch (_) {
      return _SectionResult(items: const [], error: errorMessage);
    }
  }

  Future<Map<_CitizenTeaserType, _CitizenTeaserState>> _loadCitizenTeasers({
    required bool showServices,
    required bool showCafeMeetups,
    required bool showKidsMeetups,
  }) async {
    final Map<_CitizenTeaserType, _CitizenTeaserState> results = {};
    final configs = _availableCitizenTeasers(
      showServices: showServices,
      showCafeMeetups: showCafeMeetups,
      showKidsMeetups: showKidsMeetups,
    );

    for (final config in configs) {
      try {
        final posts = await _citizenPostsService.getPostsForTypes(
          types: config.types,
        );
        results[config.type] = _CitizenTeaserState(
          posts: posts.take(3).toList(),
        );
      } catch (_) {
        results[config.type] = const _CitizenTeaserState(
          error: 'Beiträge konnten nicht geladen werden.',
        );
      }
    }

    return results;
  }

  List<_CitizenTeaserConfig> _availableCitizenTeasers({
    required bool showServices,
    required bool showCafeMeetups,
    required bool showKidsMeetups,
  }) {
    final configs = <_CitizenTeaserConfig>[];
    if (showServices) {
      configs.addAll(
        [
          _CitizenTeaserConfig(
            type: _CitizenTeaserType.postsMarket,
            title: 'Beiträge & Markt',
            types: const [
              CitizenPostType.userPost,
              CitizenPostType.marketplace,
              CitizenPostType.giveaway,
              CitizenPostType.skillExchange,
            ],
            screenBuilder: () => _buildPostsMarketScreen(),
          ),
          _CitizenTeaserConfig(
            type: _CitizenTeaserType.helpVolunteer,
            title: 'Hilfe & Ehrenamt',
            types: const [
              CitizenPostType.help,
              CitizenPostType.volunteering,
            ],
            screenBuilder: () => _buildHelpVolunteerScreen(),
          ),
        ],
      );
    }
    if (showCafeMeetups || showKidsMeetups) {
      configs.add(
        _CitizenTeaserConfig(
          type: _CitizenTeaserType.meetups,
          title: 'Treffen',
          types: [
            if (showCafeMeetups) CitizenPostType.cafeMeetup,
            if (showKidsMeetups) CitizenPostType.kidsMeetup,
          ],
          screenBuilder: () => _buildMeetupsScreen(
            showCafeMeetups: showCafeMeetups,
            showKidsMeetups: showKidsMeetups,
          ),
        ),
      );
    }
    return configs;
  }

  CategorySubHubScreen _buildPostsMarketScreen() {
    return CategorySubHubScreen(
      title: 'Beiträge & Markt',
      types: const [
        CitizenPostType.userPost,
        CitizenPostType.marketplace,
        CitizenPostType.giveaway,
        CitizenPostType.skillExchange,
      ],
      subTiles: [
        _categoryTile(
          title: 'Freier Beitrag',
          icon: Icons.chat_bubble_outline,
          type: CitizenPostType.userPost,
        ),
        _categoryTile(
          title: 'Marktplatz',
          icon: Icons.storefront,
          type: CitizenPostType.marketplace,
        ),
        _categoryTile(
          title: 'Verschenken',
          icon: Icons.card_giftcard,
          type: CitizenPostType.giveaway,
        ),
        _categoryTile(
          title: 'Talentbörse',
          icon: Icons.handshake_outlined,
          type: CitizenPostType.skillExchange,
        ),
      ],
      filterTypes: const [
        CitizenPostType.userPost,
        CitizenPostType.marketplace,
        CitizenPostType.giveaway,
        CitizenPostType.skillExchange,
      ],
      createOptions: const [
        CategoryCreateOption(
          'Marktplatz',
          CitizenPostType.marketplace,
        ),
        CategoryCreateOption(
          'Verschenken',
          CitizenPostType.giveaway,
        ),
        CategoryCreateOption(
          'Talentbörse',
          CitizenPostType.skillExchange,
        ),
      ],
    );
  }

  CategorySubHubScreen _buildHelpVolunteerScreen() {
    return CategorySubHubScreen(
      title: 'Hilfe & Ehrenamt',
      types: const [
        CitizenPostType.help,
        CitizenPostType.volunteering,
      ],
      subTiles: [
        _categoryTile(
          title: 'Hilfegesuch',
          icon: Icons.help_outline,
          type: CitizenPostType.help,
        ),
        _categoryTile(
          title: 'Hilfe anbieten',
          icon: Icons.support_agent,
          type: CitizenPostType.help,
        ),
        _categoryTile(
          title: 'Ehrenamt',
          icon: Icons.volunteer_activism,
          type: CitizenPostType.volunteering,
        ),
      ],
      filterTypes: const [
        CitizenPostType.help,
        CitizenPostType.volunteering,
      ],
      createOptions: const [
        CategoryCreateOption(
          'Hilfe anbieten',
          CitizenPostType.help,
        ),
        CategoryCreateOption(
          'Ehrenamt',
          CitizenPostType.volunteering,
        ),
      ],
    );
  }

  CategorySubHubScreen _buildMeetupsScreen({
    required bool showCafeMeetups,
    required bool showKidsMeetups,
  }) {
    return CategorySubHubScreen(
      title: 'Treffen',
      types: [
        if (showCafeMeetups) CitizenPostType.cafeMeetup,
        if (showKidsMeetups) CitizenPostType.kidsMeetup,
      ],
      subTiles: [
        if (showCafeMeetups)
          _categoryTile(
            title: 'Café-Treffen',
            icon: Icons.local_cafe,
            type: CitizenPostType.cafeMeetup,
          ),
        if (showKidsMeetups)
          _categoryTile(
            title: 'Kinder-Treffen',
            icon: Icons.child_care,
            type: CitizenPostType.kidsMeetup,
          ),
      ],
      filterTypes: [
        if (showCafeMeetups) CitizenPostType.cafeMeetup,
        if (showKidsMeetups) CitizenPostType.kidsMeetup,
      ],
      createOptions: [
        if (showCafeMeetups)
          const CategoryCreateOption(
            'Café-Treffen',
            CitizenPostType.cafeMeetup,
          ),
        if (showKidsMeetups)
          const CategoryCreateOption(
            'Kinder-Treffen',
            CitizenPostType.kidsMeetup,
          ),
      ],
    );
  }

  CategorySubTile _categoryTile({
    required String title,
    required IconData icon,
    required CitizenPostType type,
  }) {
    return CategorySubTile(
      title: title,
      icon: icon,
      type: type,
      onTap: () {
        AppRouterScope.of(context).push(
          CitizenPostsListScreen(
            title: title,
            types: [type],
            postsService: _citizenPostsService,
          ),
        );
      },
    );
  }

  List<Widget> _buildWarningsSection(List<_FeedItem> warnings) {
    if (warnings.isEmpty) {
      return const [];
    }
    return [
      const SizedBox(height: 4),
      const AppSectionHeader(
        title: 'Warnungen',
        subtitle: 'Aktive Hinweise der Gemeinde.',
      ),
      const SizedBox(height: 12),
      ...warnings.map(
        (item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _FeedListTile(
            item: item,
            formattedDate: _formatDate(item.date),
            onTap: () => _handleTap(item),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildEventsSection(
    List<_FeedItem> events, {
    String? error,
  }) {
    return [
      const SizedBox(height: 4),
      AppSectionHeader(
        title: 'Events',
        subtitle: 'Nächste Termine in den kommenden 4 Wochen.',
        trailing: TextButton(
          onPressed: () {
            AppRouterScope.of(context).push(const EventsScreen());
          },
          child: const Text('Alle Events'),
        ),
      ),
      const SizedBox(height: 12),
      if (error != null)
        _InlineStatusCard(message: error)
      else if (events.isEmpty)
        const _InlineStatusCard(
          message:
              'Noch keine Einträge. (Die Gemeinde kann Inhalte über das Web-Admin pflegen.)',
        )
      else
        ...events.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FeedListTile(
              item: item,
              formattedDate: _formatDate(item.date),
              onTap: () => _handleTap(item),
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildNewsSection(
    List<_FeedItem> news, {
    String? error,
  }) {
    return [
      const SizedBox(height: 4),
      AppSectionHeader(
        title: 'News',
        subtitle: 'Neuigkeiten aus der Gemeinde.',
        trailing: TextButton(
          onPressed: () {
            AppRouterScope.of(context).push(const NewsScreen());
          },
          child: const Text('Alle News'),
        ),
      ),
      const SizedBox(height: 12),
      if (error != null)
        _InlineStatusCard(message: error)
      else if (news.isEmpty)
        const _InlineStatusCard(
          message:
              'Noch keine Einträge. (Die Gemeinde kann Inhalte über das Web-Admin pflegen.)',
        )
      else
        ...news.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FeedListTile(
              item: item,
              formattedDate: _formatDate(item.date),
              onTap: () => _handleTap(item),
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildCitizenTeasersSection(
    List<_CitizenTeaserConfig> configs,
  ) {
    return [
      const SizedBox(height: 4),
      const AppSectionHeader(
        title: 'Bürger Aktuell',
        subtitle: 'Neueste Beiträge aus der GemeindeApp.',
      ),
      const SizedBox(height: 12),
      ...configs.map(
        (config) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _CitizenTeaserCard(
            title: config.title,
            state: _citizenTeasers[config.type],
            onTap: () {
              AppRouterScope.of(context).push(config.screenBuilder());
            },
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildLoadingSections({
    required bool showWarnings,
    required bool showEvents,
    required bool showNews,
    required List<_CitizenTeaserConfig> citizenTeasers,
  }) {
    final sections = <Widget>[];
    if (showWarnings) {
      sections.addAll(const [
        SizedBox(height: 4),
        AppSectionHeader(title: 'Warnungen'),
        SizedBox(height: 12),
        _LoadingListPlaceholder(count: 2),
      ]);
    }
    if (showEvents) {
      sections.addAll(const [
        SizedBox(height: 4),
        AppSectionHeader(title: 'Events'),
        SizedBox(height: 12),
        _LoadingListPlaceholder(count: 3),
      ]);
    }
    if (showNews) {
      sections.addAll(const [
        SizedBox(height: 4),
        AppSectionHeader(title: 'News'),
        SizedBox(height: 12),
        _LoadingListPlaceholder(count: 3),
      ]);
    }
    if (citizenTeasers.isNotEmpty) {
      sections.addAll(const [
        SizedBox(height: 4),
        AppSectionHeader(title: 'Bürger Aktuell'),
        SizedBox(height: 12),
        _LoadingListPlaceholder(count: 3),
      ]);
    }
    return sections;
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

class _SectionResult<T> {
  const _SectionResult({
    required this.items,
    this.error,
  });

  final List<T> items;
  final String? error;
}

class _CitizenTeaserConfig {
  const _CitizenTeaserConfig({
    required this.type,
    required this.title,
    required this.types,
    required this.screenBuilder,
  });

  final _CitizenTeaserType type;
  final String title;
  final List<CitizenPostType> types;
  final CategorySubHubScreen Function() screenBuilder;
}

enum _CitizenTeaserType {
  postsMarket,
  helpVolunteer,
  meetups,
}

class _CitizenTeaserState {
  const _CitizenTeaserState({
    this.posts = const [],
    this.error,
  });

  final List<CitizenPost> posts;
  final String? error;
}

class _CitizenTeaserCard extends StatelessWidget {
  const _CitizenTeaserCard({
    required this.title,
    required this.state,
    required this.onTap,
  });

  final String title;
  final _CitizenTeaserState? state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final posts = state?.posts ?? const [];
    final error = state?.error;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (error != null)
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall,
            )
          else if (posts.isEmpty)
            const Text(
              'Noch keine Einträge. (Die Gemeinde kann Inhalte über das Web-Admin pflegen.)',
            )
          else
            ...posts.map(
              (post) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _CitizenTeaserRow(post: post),
              ),
            ),
        ],
      ),
    );
  }
}

class _CitizenTeaserRow extends StatelessWidget {
  const _CitizenTeaserRow({required this.post});

  final CitizenPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          post.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${formatDate(post.createdAt)} · ${post.type.label}',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _LoadingListPlaceholder extends StatelessWidget {
  const _LoadingListPlaceholder({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (index) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: _LoadingCard(),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 16,
            width: 180,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 220,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineStatusCard extends StatelessWidget {
  const _InlineStatusCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium,
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
