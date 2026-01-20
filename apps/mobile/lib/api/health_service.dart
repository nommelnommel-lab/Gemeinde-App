import 'api_client.dart';

class HealthService {
  HealthService(this._api);

  final ApiClient _api;

  Future<String> getStatus() async {
    final json = await _api.getJson('/health');
    return (json['status'] ?? 'unknown').toString();
  }
}
