import 'package:shared_preferences/shared_preferences.dart';

class AdminKeyStore {
  AdminKeyStore(this._prefs);

  static const String _storageKeyPrefix = 'admin_key_';

  final SharedPreferences _prefs;

  String? getAdminKey(String tenantId) {
    return _prefs.getString(_keyForTenant(tenantId));
  }

  Future<void> setAdminKey(String tenantId, String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await _prefs.remove(_keyForTenant(tenantId));
    } else {
      await _prefs.setString(_keyForTenant(tenantId), trimmed);
    }
  }

  Future<void> clearAdminKey(String tenantId) async {
    await _prefs.remove(_keyForTenant(tenantId));
  }

  String _keyForTenant(String tenantId) {
    return '$_storageKeyPrefix$tenantId';
  }
}
