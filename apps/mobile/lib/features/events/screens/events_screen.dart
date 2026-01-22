import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../shared/auth/app_permissions.dart';
import '../../../shared/di/app_services_scope.dart';
import '../../../shared/navigation/app_router.dart';
import '../models/event.dart';
import '../services/events_service.dart';
import 'event_detail_screen.dart';
import 'event_form_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late final EventsService _eventsService;
  bool _initialized = false;

  bool _loading = true;
  String? _error;
  List<Event> _events = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _eventsService = AppServicesScope.of(context).eventsService;
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
      if (!mounted) return;
      setState(() {
        _events = events;
      });
    } catch (e) {
      debugPrint('Events loading failed: $e');
      setState(
        () => _error =
            'Events konnten nicht geladen werden. Bitte später erneut versuchen.',
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit =
        AppPermissionsScope.maybePermissionsOf(context)?.canManageContent ??
            false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRouterScope.of(context).pop(),
        ),
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: _openCreateEvent,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const _LoadingSkeleton();
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ErrorView(error: _error!, onRetry: _load),
        ],
      );
    }

    if (_events.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.event_busy, size: 64, color: Colors.black54),
          SizedBox(height: 16),
          Center(
            child: Text(
              'Keine Events in den nächsten 4 Wochen.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Text(
              'Schau später noch einmal vorbei.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final event = _events[index];
        return Card(
          child: ListTile(
            title: Text(
              event.title.isEmpty ? 'Unbenanntes Event' : event.title,
            ),
            subtitle: Text(
              '${_formatDate(event.date)} · ${_displayLocation(event.location)}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _openEventDetail(event);
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

  String _displayLocation(String location) {
    final trimmed = location.trim();
    return trimmed.isEmpty ? 'Ort wird noch bekannt gegeben' : trimmed;
  }

  Future<void> _openEventDetail(Event event) async {
    final canEdit =
        AppPermissionsScope.maybePermissionsOf(context)?.canManageContent ??
            false;
    final result = await AppRouterScope.of(context).push(
      EventDetailScreen(
        event: event,
        eventsService: _eventsService,
        canEdit: canEdit,
      ),
    );
    if (result == true) {
      await _load();
    }
  }

  Future<void> _openCreateEvent() async {
    final result = await AppRouterScope.of(context).push(
      EventFormScreen(eventsService: _eventsService),
    );
    if (result != null) {
      await _load();
    }
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Etwas ist schiefgelaufen',
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
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 12,
                  width: 140,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
