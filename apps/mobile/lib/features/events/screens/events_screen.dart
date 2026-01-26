import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../shared/auth/app_permissions.dart';
import '../../../shared/auth/auth_scope.dart';
import '../../../shared/di/app_services_scope.dart';
import '../../../shared/navigation/app_router.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../auth/screens/login_screen.dart';
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
  static const _emptyHint =
      'Einträge können von der Verwaltung im Web-Admin ergänzt werden.';
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
    final permissions =
        AppPermissionsScope.maybePermissionsOf(context) ?? AppPermissions.empty;
    final isAuthenticated = AuthScope.of(context).isAuthenticated;
    final canEdit = isAuthenticated && permissions.canCreate.officialEvents;

    return AppScaffold(
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
              label: const Text('Hinzufügen'),
            )
          : null,
      padBody: false,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return _buildStateList(const LoadingState(message: 'Events werden geladen...'));
    }

    if (_error != null) {
      final normalized = _error!.toLowerCase();
      final isAuthError = normalized.contains('http 401') ||
          normalized.contains('http 403') ||
          normalized.contains('sitzung abgelaufen');
      return _buildStateList(
        ErrorState(
          message: _error!,
          onRetry: _load,
          secondaryAction: isAuthError
              ? OutlinedButton(
                  onPressed: () {
                    AppRouterScope.of(context).push(const LoginScreen());
                  },
                  child: const Text('Anmelden'),
                )
              : null,
        ),
      );
    }

    if (_events.isEmpty) {
      return _buildStateList(
        const EmptyState(
          icon: Icons.event_busy,
          title: 'Noch keine Einträge',
          message: 'Aktuell sind keine Events geplant.',
          hint: _emptyHint,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final event = _events[index];
        return AppCard(
          onTap: () => _openEventDetail(event),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title.isEmpty ? 'Unbenanntes Event' : event.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppChip(
                    label: _formatDate(event.date),
                    icon: Icons.event,
                  ),
                  AppChip(
                    label: _displayLocation(event.location),
                    icon: Icons.place_outlined,
                  ),
                ],
              ),
            ],
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
    final permissions =
        AppPermissionsScope.maybePermissionsOf(context) ?? AppPermissions.empty;
    final isAuthenticated = AuthScope.of(context).isAuthenticated;
    final canEdit = isAuthenticated && permissions.canCreate.officialEvents;
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

  Widget _buildStateList(Widget child) {
    return ListView(
      padding: const EdgeInsets.all(24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        child,
      ],
    );
  }
}
