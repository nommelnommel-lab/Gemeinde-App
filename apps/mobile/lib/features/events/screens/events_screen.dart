import 'package:flutter/material.dart';

import '../../../shared/navigation/app_router.dart';
import '../models/event.dart';
import '../services/events_service.dart';
import 'event_detail_screen.dart';
import 'event_form_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({
    super.key,
    required this.eventsService,
  });

  final EventsService eventsService;

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorView(error: _error!, onRetry: _load);
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _load,
          child: _events.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 120),
                    Center(
                      child: Text(
                        'Zurzeit sind keine Veranstaltungen geplant.',
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    return Card(
                      child: ListTile(
                        title: Text(event.title),
                        subtitle:
                            Text('${_formatDate(event.date)} · ${event.location}'),
                        trailing: PopupMenuButton<_EventAction>(
                          onSelected: (action) => _handleAction(action, event),
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: _EventAction.edit,
                              child: Text('Bearbeiten'),
                            ),
                            PopupMenuItem(
                              value: _EventAction.delete,
                              child: Text('Löschen'),
                            ),
                          ],
                        ),
                        onTap: () async {
                          final result =
                              await AppRouterScope.of(context).push<bool>(
                            EventDetailScreen(
                              event: event,
                              eventsService: _eventsService,
                            ),
                          );
                          if (result == true) {
                            _load();
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _openCreate,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  Future<void> _openCreate() async {
    final result = await AppRouterScope.of(context).push<bool>(
      EventFormScreen(eventsService: _eventsService),
    );
    if (result == true) {
      _load();
    }
  }

  Future<void> _handleAction(_EventAction action, Event event) async {
    switch (action) {
      case _EventAction.edit:
        final result = await AppRouterScope.of(context).push<bool>(
          EventFormScreen(eventsService: _eventsService, event: event),
        );
        if (result == true) {
          _load();
        }
        break;
      case _EventAction.delete:
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Event löschen'),
            content: const Text('Möchtest du dieses Event wirklich löschen?'),
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
          ),
        );
        if (confirm != true) return;
        try {
          await _eventsService.deleteEvent(event.id);
          _load();
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Löschen: $e')),
          );
        }
        break;
    }
  }
}

enum _EventAction { edit, delete }

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
                'Events konnten nicht geladen werden',
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
