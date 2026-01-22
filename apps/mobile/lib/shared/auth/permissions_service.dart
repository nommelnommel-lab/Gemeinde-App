import '../../api/api_client.dart';
import 'app_permissions.dart';

class PermissionsService {
  PermissionsService(this._apiClient);

  final ApiClient _apiClient;

  Future<AppPermissions> getPermissions() async {
    try {
      final data = await _apiClient.getJsonFlexible('/permissions');
      final payload = _extractPayload(data);
      final canManage = _readBool(
            payload['canManageContent'],
          ) ??
          _readBool(payload['admin']) ??
          _readBool(payload['isAdmin']) ??
          _readBool(payload['canManage']);
      return AppPermissions(canManageContent: canManage ?? false);
    } catch (_) {
      return const AppPermissions(canManageContent: false);
    }
  }

  Map<String, dynamic> _extractPayload(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'] ?? data['permissions'];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
      return data;
    }
    return const <String, dynamic>{};
  }

  bool? _readBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      if (value.toLowerCase() == 'true') {
        return true;
      }
      if (value.toLowerCase() == 'false') {
        return false;
      }
    }
    if (value is num) {
      return value != 0;
    }
    return null;
  }
}
