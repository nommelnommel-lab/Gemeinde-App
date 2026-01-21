import '../../../api/api_client.dart';
import '../models/event.dart';

class EventsService {
  EventsService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Event>> getEvents() async {
    final data = await _apiClient.getJsonList('/events');
    return data
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
