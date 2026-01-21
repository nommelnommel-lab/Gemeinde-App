import 'package:flutter/material.dart';

import '../../../shared/navigation/app_router.dart';
import '../models/event.dart';
import '../services/events_service.dart';
import 'event_detail_screen.dart';

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

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final event = _events[index];
        return Card(
          child: ListTile(
            title: Text(event.title),
            subtitle: Text('${_formatDate(event.date)} · ${event.location}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              AppRouterScope.of(context).push(
                EventDetailScreen(event: event),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
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
