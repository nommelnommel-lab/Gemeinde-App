import '../../../api/api_client.dart';
import '../models/tenant_config.dart';

class TenantConfigService {
  TenantConfigService(this._apiClient);

  final ApiClient _apiClient;

  Future<TenantConfig> getTenantConfig() async {
    final data = await _loadConfig('/api/tenant/settings');
    return TenantConfig.fromJson(data);
  }

  Future<Map<String, dynamic>> _loadConfig(String path) async {
    try {
      final data = await _apiClient.getJson(path);
      return _extractPayload(data);
    } on ApiException catch (error) {
      if (error.statusCode == 404 && path == '/api/tenant/settings') {
        final data = await _apiClient.getJson('/api/tenant/config');
        return _extractPayload(data);
      }
      rethrow;
    }
  }

  Map<String, dynamic> _extractPayload(Map<String, dynamic> data) {
    final nested = data['data'] ?? data['tenant'] ?? data['config'];
    if (nested is Map<String, dynamic>) {
      return nested;
    }
    return data;
  }
}
