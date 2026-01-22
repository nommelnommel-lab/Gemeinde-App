import 'package:flutter/foundation.dart';

import '../../../api/api_client.dart';
import '../models/event.dart';
import '../models/event_input.dart';
import '../models/event_permissions.dart';

class EventsService {
  EventsService(this._apiClient, {bool useStub = false}) : _useStub = useStub;

  final ApiClient _apiClient;
  final bool _useStub;
  int _stubCounter = 0;
  final List<Event> _stubEvents = [];

  Future<EventsPermissions> getPermissions() async {
    if (_useStub) {
      return const EventsPermissions(canManageContent: true);
    }

    try {
      final data = await _apiClient.getJsonFlexible('/events/permissions');
      if (data is Map<String, dynamic>) {
        return EventsPermissions.fromJson(data);
      }
      return const EventsPermissions(canManageContent: true);
    } catch (_) {
      return const EventsPermissions(canManageContent: true);
    }
  }

  Future<List<Event>> getEvents() async {
    if (_useStub) {
      return _getStubEvents();
    }

    final from = DateTime.now().toIso8601String();
    final path =
        '/api/feed/events?from=${Uri.encodeQueryComponent(from)}&weeks=4';

    try {
      final response = await _apiClient.getJsonFlexibleWithResponse(path);
      if (kDebugMode) {
        debugPrint('GET ${response.uri} -> ${response.statusCode}');
        debugPrint('Events response type: ${response.data.runtimeType}');
        if (response.data is Map<String, dynamic>) {
          debugPrint('Events response keys: ${response.data.keys.toList()}');
        }
      }

      final List<dynamic> items;
      if (response.data is List<dynamic>) {
        items = response.data as List<dynamic>;
      } else if (response.data is Map<String, dynamic>) {
        final data =
            (response.data as Map<String, dynamic>)['data'] ??
                (response.data as Map<String, dynamic>)['events'];
        if (kDebugMode) {
          debugPrint('Events list container type: ${data.runtimeType}');
        }
        if (data is List<dynamic>) {
          items = data;
        } else {
          throw Exception('Unerwartetes /api/feed/events Format: list fehlt');
        }
      } else {
        throw Exception(
          'Unerwartetes /api/feed/events Format: ${response.data.runtimeType}',
        );
      }

      final events = items
          .whereType<Map<String, dynamic>>()
          .map(_mapFeedEvent)
          .toList();
      if (kDebugMode) {
        debugPrint('Events loaded: ${events.length}');
      }
      return events;
    } on ApiException catch (error) {
      if (kDebugMode) {
        debugPrint(
          'GET ${_apiClient.baseUrl}$path -> ${error.statusCode ?? 'error'}',
        );
      }
      rethrow;
    }
  }

  Future<Event> getEvent(String id) async {
    if (_useStub) {
      return _getStubEvent(id);
    }

    try {
      final data = await _apiClient.getJson('/events/$id');
      return Event.fromJson(data);
    } catch (_) {
      return _getStubEvent(id);
    }
  }

  Future<Event> createEvent(EventInput input) async {
    if (_useStub) {
      return _createStubEvent(input);
    }

    try {
      final data = await _apiClient.postJson('/events', input.toJson());
      return Event.fromJson(data);
    } catch (_) {
      return _createStubEvent(input);
    }
  }

  Future<Event> updateEvent(String id, EventInput input) async {
    if (_useStub) {
      return _updateStubEvent(id, input);
    }

    try {
      final data = await _apiClient.putJson('/events/$id', input.toJson());
      return Event.fromJson(data);
    } catch (_) {
      return _updateStubEvent(id, input);
    }
  }

  Future<void> deleteEvent(String id) async {
    if (_useStub) {
      _deleteStubEvent(id);
      return;
    }

    try {
      await _apiClient.deleteJson('/events/$id');
    } catch (_) {
      _deleteStubEvent(id);
    }
  }

  Event _mapFeedEvent(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    normalized['date'] ??= json['startAt'] ?? json['start_at'];
    normalized['createdAt'] ??= json['created_at'] ?? normalized['date'];
    normalized['updatedAt'] ??= json['updated_at'] ?? normalized['date'];
    return Event.fromJson(normalized);
  }

  List<Event> _getStubEvents() {
    if (_stubEvents.isEmpty) {
      final now = DateTime.now();
      _stubEvents
        ..addAll([
          Event(
            id: _nextStubId(),
            title: 'Bürgertreff im Rathaus',
            description: 'Ein Austausch für alle Interessierten aus der Gemeinde.',
            date: now.add(const Duration(days: 5)),
            location: 'Rathausplatz 1',
            createdAt: now,
            updatedAt: now,
          ),
          Event(
            id: _nextStubId(),
            title: 'Sommerfest im Park',
            description: 'Gemeinsames Picknick mit Musik und Spielen.',
            date: now.add(const Duration(days: 18, hours: 2)),
            location: 'Stadtpark',
            createdAt: now,
            updatedAt: now,
          ),
        ]);
    }
    return List<Event>.unmodifiable(_stubEvents);
  }

  Event _getStubEvent(String id) {
    return _stubEvents.firstWhere(
      (event) => event.id == id,
      orElse: () => _stubEvents.isNotEmpty
          ? _stubEvents.first
          : Event(
              id: id,
              title: '',
              description: '',
              date: DateTime.now(),
              location: '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
    );
  }

  Event _createStubEvent(EventInput input) {
    final now = DateTime.now();
    final event = Event(
      id: _nextStubId(),
      title: input.title,
      description: input.description,
      date: input.date,
      location: input.location,
      createdAt: now,
      updatedAt: now,
    );
    _stubEvents.insert(0, event);
    return event;
  }

  Event _updateStubEvent(String id, EventInput input) {
    final index = _stubEvents.indexWhere((event) => event.id == id);
    final now = DateTime.now();
    if (index == -1) {
      final event = Event(
        id: id,
        title: input.title,
        description: input.description,
        date: input.date,
        location: input.location,
        createdAt: now,
        updatedAt: now,
      );
      _stubEvents.insert(0, event);
      return event;
    }

    final existing = _stubEvents[index];
    final updated = Event(
      id: existing.id,
      title: input.title,
      description: input.description,
      date: input.date,
      location: input.location,
      createdAt: existing.createdAt,
      updatedAt: now,
    );
    _stubEvents[index] = updated;
    return updated;
  }

  void _deleteStubEvent(String id) {
    _stubEvents.removeWhere((event) => event.id == id);
  }

  String _nextStubId() {
    _stubCounter += 1;
    return 'stub-event-$_stubCounter';
  }
}
