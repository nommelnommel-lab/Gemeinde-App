import 'package:flutter/material.dart';

import '../../events/models/event.dart';
import '../../events/services/events_service.dart';

class StartFeedScreen extends StatefulWidget {
  const StartFeedScreen({
    super.key,
    required this.onSelectTab,
    required this.eventsService,
  });

  final ValueChanged<int> onSelectTab;
  final EventsService eventsService;

  @override
  State<StartFeedScreen> createState() => _StartFeedScreenState();
}

class _StartFeedScreenState extends State<StartFeedScreen> {
  late final EventsService _eventsService;

  bool _loading = true;
  String? _error;
  List<Event> _events = const [];

  @override
  void initState() {
    super.initState();
    _eventsService = widget.eventsService;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final events = await _eventsService.getEvents();
      setState(() => _events = events);
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
            onTap: () => widget.onSelectTab(1),
          ),
          const SizedBox(height: 16),
          _StartCard(
            title: 'Verwaltung',
            subtitle: 'Formulare und Infos aus der Gemeinde',
            icon: Icons.admin_panel_settings,
            onTap: () => widget.onSelectTab(2),
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
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
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
