import 'package:flutter/material.dart';

import '../../../shared/di/app_services_scope.dart';
import '../../../shared/navigation/app_router.dart';
import '../../../shared/widgets/placeholder_content.dart';
import '../../events/screens/events_screen.dart';
import '../../events/services/events_service.dart';
import '../../news/services/news_service.dart';
import '../../warnings/services/warnings_service.dart';
import '../models/start_feed_preview_item.dart';
import '../services/start_feed_extras_service.dart';

enum StartFeedSectionType {
  warnings,
  news,
  events,
  cafeTreff,
  seniorenHilfe,
  flohmarkt,
  umzugEntruempelung,
  kinderSpielen,
}

class StartFeedScreen extends StatefulWidget {
  const StartFeedScreen({
    super.key,
    this.extrasService,
  });

  final StartFeedExtrasService? extrasService;

  @override
  State<StartFeedScreen> createState() => _StartFeedScreenState();
}

class _StartFeedScreenState extends State<StartFeedScreen> {
  late final EventsService _eventsService;
  late final WarningsService _warningsService;
  late final NewsService _newsService;
  late final StartFeedExtrasService _extrasService;
  bool _initialized = false;

  final Map<StartFeedSectionType, _SectionState> _sections = {};

  List<_SectionDescriptor> get _sectionDescriptors => const [
        _SectionDescriptor(
          type: StartFeedSectionType.warnings,
          title: 'Warnungen',
          description: 'Aktuelle Hinweise und wichtige Meldungen.',
          icon: Icons.warning_amber,
        ),
        _SectionDescriptor(
          type: StartFeedSectionType.news,
          title: 'Aktuelles / News',
          description: 'Neuigkeiten aus der Gemeinde auf einen Blick.',
          icon: Icons.newspaper,
        ),
        _SectionDescriptor(
          type: StartFeedSectionType.events,
          title: 'Nächste Events',
          description: 'Bevorstehende Veranstaltungen und Termine.',
          icon: Icons.event,
        ),
        _SectionDescriptor(
          type: StartFeedSectionType.cafeTreff,
          title: 'Café Treff',
          description: 'Kaffee trinken und Nachbarn kennenlernen.',
          icon: Icons.local_cafe,
        ),
        _SectionDescriptor(
          type: StartFeedSectionType.seniorenHilfe,
          title: 'Senioren Hilfe',
          description: 'Unterstützung und Begleitung für Senior:innen.',
          icon: Icons.volunteer_activism,
        ),
        _SectionDescriptor(
          type: StartFeedSectionType.flohmarkt,
          title: 'Flohmarkt',
          description: 'Stöbern, tauschen und verkaufen in der Gemeinde.',
          icon: Icons.storefront,
        ),
        _SectionDescriptor(
          type: StartFeedSectionType.umzugEntruempelung,
          title: 'Umzug / Entrümpelung',
          description: 'Hilfe organisieren und Nachbarschaft anfragen.',
          icon: Icons.local_shipping,
        ),
        _SectionDescriptor(
          type: StartFeedSectionType.kinderSpielen,
          title: 'Kinderspielen',
          description: 'Spielgruppen und Treffen für Familien.',
          icon: Icons.child_friendly,
        ),
      ];

  @override
  void initState() {
    super.initState();
    for (final type in StartFeedSectionType.values) {
      _sections[type] = const _SectionState.loading();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final services = AppServicesScope.of(context);
    _eventsService = services.eventsService;
    _warningsService = services.warningsService;
    _newsService = services.newsService;
    _extrasService = widget.extrasService ?? StartFeedExtrasService();
    _initialized = true;
    _loadAllSections();
  }

  Future<void> _loadAllSections() {
    setState(() {
      for (final type in StartFeedSectionType.values) {
        _sections[type] = _sections[type]!.copyWith(isLoading: true, error: null);
      }
    });

    return Future.wait([
      _loadWarnings(),
      _loadNews(),
      _loadEvents(),
      _loadCafeTreff(),
      _loadSeniorenHilfe(),
      _loadFlohmarkt(),
      _loadUmzugEntruempelung(),
      _loadKinderSpielen(),
    ]);
  }

  Future<void> _loadWarnings() async {
    await _loadSection(
      StartFeedSectionType.warnings,
      () async {
        final warnings = await _warningsService.getWarnings();
        final sorted = [...warnings]
          ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        return sorted
            .take(3)
            .map(
              (warning) => StartFeedPreviewItem(
                title: warning.title,
                subtitle: warning.body,
              ),
            )
            .toList();
      },
    );
  }

  Future<void> _loadNews() async {
    await _loadSection(
      StartFeedSectionType.news,
      () async {
        final news = await _newsService.getNews();
        final sorted = [...news]
          ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        return sorted
            .take(3)
            .map(
              (item) => StartFeedPreviewItem(
                title: item.title,
                subtitle: item.summary,
              ),
            )
            .toList();
      },
    );
  }

  Future<void> _loadEvents() async {
    await _loadSection(
      StartFeedSectionType.events,
      () async {
        final events = await _eventsService.getEvents();
        final sorted = [...events]..sort((a, b) => a.date.compareTo(b.date));
        return sorted
            .take(3)
            .map(
              (event) => StartFeedPreviewItem(
                title: event.title,
                subtitle: '${_formatDate(event.date)} · ${event.location}',
              ),
            )
            .toList();
      },
    );
  }

  Future<void> _loadCafeTreff() async {
    await _loadSection(
      StartFeedSectionType.cafeTreff,
      _extrasService.getCafeTreff,
    );
  }

  Future<void> _loadSeniorenHilfe() async {
    await _loadSection(
      StartFeedSectionType.seniorenHilfe,
      _extrasService.getSeniorenHilfe,
    );
  }

  Future<void> _loadFlohmarkt() async {
    await _loadSection(
      StartFeedSectionType.flohmarkt,
      _extrasService.getFlohmarkt,
    );
  }

  Future<void> _loadUmzugEntruempelung() async {
    await _loadSection(
      StartFeedSectionType.umzugEntruempelung,
      _extrasService.getUmzugEntruempelung,
    );
  }

  Future<void> _loadKinderSpielen() async {
    await _loadSection(
      StartFeedSectionType.kinderSpielen,
      _extrasService.getKinderSpielen,
    );
  }

  Future<void> _loadSection(
    StartFeedSectionType type,
    Future<List<StartFeedPreviewItem>> Function() loader,
  ) async {
    _setSectionState(
      type,
      _sections[type]!.copyWith(isLoading: true, error: null),
    );

    try {
      final items = await loader();
      _setSectionState(
        type,
        _sections[type]!.copyWith(
          isLoading: false,
          error: null,
          items: items,
        ),
      );
    } catch (error) {
      _setSectionState(
        type,
        _sections[type]!.copyWith(
          isLoading: false,
          error: error.toString(),
        ),
      );
    }
  }

  void _setSectionState(StartFeedSectionType type, _SectionState state) {
    if (!mounted) {
      return;
    }
    setState(() => _sections[type] = state);
  }

  void _handleAction(StartFeedSectionType type) {
    switch (type) {
      case StartFeedSectionType.events:
        AppRouterScope.of(context).push(const EventsScreen());
        return;
      case StartFeedSectionType.warnings:
        _openComingSoon(
          title: 'Warnungen',
          description: 'Alle Warnmeldungen werden hier gesammelt angezeigt.',
        );
        return;
      case StartFeedSectionType.news:
        _openComingSoon(
          title: 'Aktuelles',
          description: 'Hier findest du bald alle News aus der Gemeinde.',
        );
        return;
      case StartFeedSectionType.cafeTreff:
        _openComingSoon(
          title: 'Café Treff',
          description: 'Entdecke bald alle Café-Treffen in deiner Umgebung.',
        );
        return;
      case StartFeedSectionType.seniorenHilfe:
        _openComingSoon(
          title: 'Senioren Hilfe',
          description: 'Angebote zur Unterstützung werden hier gesammelt.',
        );
        return;
      case StartFeedSectionType.flohmarkt:
        _openComingSoon(
          title: 'Flohmarkt',
          description: 'Finde bald alle Flohmarkt-Angebote auf einen Blick.',
        );
        return;
      case StartFeedSectionType.umzugEntruempelung:
        _openComingSoon(
          title: 'Umzug / Entrümpelung',
          description: 'Hilfegesuche und Angebote werden hier sichtbar.',
        );
        return;
      case StartFeedSectionType.kinderSpielen:
        _openComingSoon(
          title: 'Kinderspielen',
          description: 'Spielgruppen und Treffen werden hier gesammelt.',
        );
        return;
    }
  }

  void _openComingSoon({required String title, required String description}) {
    AppRouterScope.of(context).push(
      ComingSoonScreen(title: title, description: description),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadAllSections,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _sectionDescriptors.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final descriptor = _sectionDescriptors[index];
          final sectionState =
              _sections[descriptor.type] ?? const _SectionState.loading();
          return _FeedSectionCard(
            descriptor: descriptor,
            state: sectionState,
            onRetry: () => _retrySection(descriptor.type),
            onAction: () => _handleAction(descriptor.type),
          );
        },
      ),
    );
  }

  void _retrySection(StartFeedSectionType type) {
    switch (type) {
      case StartFeedSectionType.warnings:
        _loadWarnings();
        return;
      case StartFeedSectionType.news:
        _loadNews();
        return;
      case StartFeedSectionType.events:
        _loadEvents();
        return;
      case StartFeedSectionType.cafeTreff:
        _loadCafeTreff();
        return;
      case StartFeedSectionType.seniorenHilfe:
        _loadSeniorenHilfe();
        return;
      case StartFeedSectionType.flohmarkt:
        _loadFlohmarkt();
        return;
      case StartFeedSectionType.umzugEntruempelung:
        _loadUmzugEntruempelung();
        return;
      case StartFeedSectionType.kinderSpielen:
        _loadKinderSpielen();
        return;
    }
  }
}

class _FeedSectionCard extends StatelessWidget {
  const _FeedSectionCard({
    required this.descriptor,
    required this.state,
    required this.onRetry,
    required this.onAction,
  });

  final _SectionDescriptor descriptor;
  final _SectionState state;
  final VoidCallback onRetry;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  child: Icon(descriptor.icon, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    descriptor.title,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              descriptor.description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _SectionBody(state: state, onRetry: onRetry),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onAction,
                child: const Text('Alle ansehen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({required this.state, required this.onRetry});

  final _SectionState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (state.isLoading) {
      return Row(
        children: [
          const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text('Lädt...', style: theme.textTheme.bodyMedium),
        ],
      );
    }

    if (state.error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fehler beim Laden.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            state.error!,
            style: theme.textTheme.bodySmall,
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Erneut versuchen'),
          ),
        ],
      );
    }

    if (state.items.isEmpty) {
      return Text(
        'Zurzeit gibt es keine Einträge.',
        style: theme.textTheme.bodyMedium,
      );
    }

    return Column(
      children: state.items
          .take(3)
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SectionDescriptor {
  const _SectionDescriptor({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
  });

  final StartFeedSectionType type;
  final String title;
  final String description;
  final IconData icon;
}

class _SectionState {
  const _SectionState({
    required this.isLoading,
    required this.items,
    this.error,
  });

  const _SectionState.loading()
      : isLoading = true,
        items = const [],
        error = null;

  final bool isLoading;
  final List<StartFeedPreviewItem> items;
  final String? error;

  _SectionState copyWith({
    bool? isLoading,
    List<StartFeedPreviewItem>? items,
    String? error,
  }) {
    return _SectionState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      error: error,
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
      body: PlaceholderContent(title: title, description: description),
    );
  }
}
