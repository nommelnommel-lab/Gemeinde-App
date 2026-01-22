import 'package:flutter/material.dart';

import '../../../shared/navigation/app_router.dart';
import '../../../shared/widgets/coming_soon_content.dart';
import '../../events/models/event.dart';
import '../../events/screens/event_detail_screen.dart';
import '../../events/services/events_service.dart';
import '../models/feed_item.dart';
import '../widgets/feed_card.dart';

class StartFeedScreen extends StatefulWidget {
  const StartFeedScreen({
    super.key,
    required this.eventsService,
  });

  final EventsService eventsService;

  @override
  State<StartFeedScreen> createState() => _StartFeedScreenState();
}

class _StartFeedScreenState extends State<StartFeedScreen> {
  bool _loading = true;
  String? _error;
  List<FeedItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final events = await widget.eventsService.getEvents();
      final items = _buildFeedItems(events);
      setState(() => _items = items);
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
        type: FeedItemType.warning,
        title: 'Baustelle auf der Hauptstraße',
        body: 'Bitte mit Verzögerungen im Verkehr rechnen.',
        date: now.subtract(const Duration(days: 1, hours: 2)),
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
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _items[index];
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
      AppRouterScope.of(context).push(
        EventDetailScreen(event: item.event!),
      );
      return;
    }

    final description = _comingSoonDescription(item.type);
    AppRouterScope.of(context).push(
      ComingSoonScreen(title: item.title, description: description),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
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
