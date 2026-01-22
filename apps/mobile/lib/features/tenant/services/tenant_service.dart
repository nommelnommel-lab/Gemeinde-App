import '../../../api/api_client.dart';
import '../models/tenant_config.dart';

class TenantService {
  TenantService(this._apiClient);

  final ApiClient _apiClient;

  Future<TenantConfig> getTenantConfig() async {
    final data = await _apiClient.getJsonFlexible('/tenant/config');
    final payload = _extractPayload(data);
    return TenantConfig.fromJson(payload);
  }

  Future<TenantConfig> updateTenantConfig(
    TenantConfig config, {
    String? adminKeyOverride,
  }) async {
    final data = await _apiClient.putJson(
      '/tenant/config',
      config.toJson(),
      includeAdminKey: true,
      adminKeyOverride: adminKeyOverride,
    );
    final payload = _extractPayload(data);
    return TenantConfig.fromJson(payload);
  }

  Map<String, dynamic> _extractPayload(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'] ?? data['tenant'] ?? data['config'];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
      return data;
    }
    return const <String, dynamic>{};
  }
}
