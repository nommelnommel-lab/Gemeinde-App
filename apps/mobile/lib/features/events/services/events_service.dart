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
}
