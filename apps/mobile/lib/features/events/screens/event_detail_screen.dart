import 'package:flutter/material.dart';

import '../../../shared/navigation/app_router.dart';
import '../models/event.dart';
import '../models/event_permissions.dart';
import '../services/events_service.dart';
import 'event_form_screen.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.event,
    required this.eventsService,
    required this.permissions,
  });

  final Event event;
  final EventsService eventsService;
  final EventsPermissions permissions;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Event _event;
  bool _deleting = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  @override
  Widget build(BuildContext context) {
    final title = _event.title.trim();
    final location = _event.location.trim().isEmpty
        ? 'Ort wird noch bekannt gegeben'
        : _event.location.trim();
    final description = _event.description.trim().isEmpty
        ? 'Keine Beschreibung verfügbar.'
        : _event.description.trim();

    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title.isEmpty ? 'Event' : title),
          leadingWidth: 96,
          leading: TextButton.icon(
            onPressed: () => AppRouterScope.of(context).pop(_hasChanges),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Zurück'),
          ),
          actions: widget.permissions.canManageContent
              ? [
                  IconButton(
                    tooltip: 'Bearbeiten',
                    icon: const Icon(Icons.edit),
                    onPressed: _deleting ? null : _editEvent,
                  ),
                  IconButton(
                    tooltip: 'Löschen',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _deleting ? null : _confirmDelete,
                  ),
                ]
              : null,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDate(_event.date),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(description, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editEvent() async {
    final updated = await AppRouterScope.of(context).push<Event>(
      EventFormScreen(eventsService: widget.eventsService, event: _event),
    );
    if (!mounted) return;
    if (updated != null) {
      setState(() {
        _event = updated;
        _hasChanges = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event aktualisiert.')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Event löschen?'),
          content: const Text(
            'Möchtest du dieses Event wirklich löschen? Dieser Schritt kann nicht rückgängig gemacht werden.',
          ),
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
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await widget.eventsService.deleteEvent(_event.id);
      if (!mounted) return;
      AppRouterScope.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Löschen fehlgeschlagen: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  Future<bool> _handleWillPop() async {
    AppRouterScope.of(context).pop(_hasChanges);
    return false;
  }
}
