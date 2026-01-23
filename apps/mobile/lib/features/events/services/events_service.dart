import 'package:flutter/foundation.dart';

import '../../../api/api_client.dart';
import '../models/event.dart';
import '../models/event_input.dart';
import '../models/event_permissions.dart';

class EventsService {
  EventsService(this._apiClient);

  final ApiClient _apiClient;

  Future<EventsPermissions> getPermissions() async {
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
    final from = DateTime.now().toIso8601String();
    final path =
        '/api/feed/events?from=${Uri.encodeQueryComponent(from)}&weeks=4';

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
  }

  Future<Event> getEvent(String id) async {
    final events = await getEvents();
    return events.firstWhere(
      (event) => event.id == id,
      orElse: () => throw Exception('Event nicht gefunden'),
    );
  }

  Future<Event> createEvent(EventInput input) async {
    final data = await _apiClient.postJson('/api/admin/events', input.toJson());
    return Event.fromJson(data);
  }

  Future<Event> updateEvent(String id, EventInput input) async {
    final data =
        await _apiClient.putJson('/api/admin/events/$id', input.toJson());
    return Event.fromJson(data);
  }

  Future<void> deleteEvent(String id) async {
    await _apiClient.deleteJson('/api/admin/events/$id');
  }

  Event _mapFeedEvent(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    normalized['date'] ??= json['startAt'] ?? json['start_at'];
    normalized['createdAt'] ??= json['created_at'] ?? normalized['date'];
    normalized['updatedAt'] ??= json['updated_at'] ?? normalized['date'];
    return Event.fromJson(normalized);
  }
}
