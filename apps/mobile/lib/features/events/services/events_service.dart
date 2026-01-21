import 'package:flutter/foundation.dart';

import '../../../api/api_client.dart';
import '../models/event.dart';

class EventsService {
  EventsService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Event>> getEvents() async {
    final response = await _apiClient.getJsonFlexible('/events');
    if (kDebugMode) {
      debugPrint('Events response type: ${response.runtimeType}');
      if (response is Map<String, dynamic>) {
        debugPrint('Events response keys: ${response.keys.toList()}');
      }
    }

    final List<dynamic> items;
    if (response is List<dynamic>) {
      items = response;
    } else if (response is Map<String, dynamic>) {
      final data = response['data'] ?? response['events'];
      if (kDebugMode) {
        debugPrint('Events list container type: ${data.runtimeType}');
      }
      if (data is List<dynamic>) {
        items = data;
      } else {
        throw Exception('Unerwartetes /events Format: list fehlt');
      }
    } else {
      throw Exception('Unerwartetes /events Format: ${response.runtimeType}');
    }

    if (kDebugMode && items.isNotEmpty) {
      final sample = items.first;
      if (sample is Map<String, dynamic>) {
        debugPrint('Events sample keys: ${sample.keys.toList()}');
      }
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(Event.fromJson)
        .toList();
  }

  Future<Event> getEvent(String id) async {
    final data = await _apiClient.getJson('/events/$id');
    return Event.fromJson(data);
  }

  Future<Event> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required String location,
  }) async {
    final data = await _apiClient.postJson('/events', {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'location': location,
    });
    return Event.fromJson(data);
  }

  Future<Event> updateEvent(
    String id, {
    required String title,
    required String description,
    required DateTime date,
    required String location,
  }) async {
    final data = await _apiClient.putJson('/events/$id', {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'location': location,
    });
    return Event.fromJson(data);
  }

  Future<void> deleteEvent(String id) async {
    await _apiClient.deleteJson('/events/$id');
  }
}
