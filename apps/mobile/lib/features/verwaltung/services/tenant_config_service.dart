import '../../../api/api_client.dart';
import '../models/tenant_config.dart';

class TenantConfigService {
  TenantConfigService(this._apiClient);

  final ApiClient _apiClient;

  Future<TenantConfig> getTenantConfig() async {
    final data = await _apiClient.getJson('/tenant/config');
    return TenantConfig.fromJson(data);
  }
}
