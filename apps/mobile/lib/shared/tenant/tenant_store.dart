import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TenantStore {
  TenantStore(this._prefs, {String defaultTenantId = 'demo'})
      : _defaultTenantId = defaultTenantId,
        tenantIdNotifier = ValueNotifier<String>(defaultTenantId);

  static const _prefsKey = 'tenant_id';

  final SharedPreferences _prefs;
  final String _defaultTenantId;
  final ValueNotifier<String> tenantIdNotifier;

  Future<String> getTenantId() async {
    final stored = _prefs.getString(_prefsKey);
    final tenantId = stored != null && stored.isNotEmpty
        ? stored
        : _defaultTenantId;
    if (tenantIdNotifier.value != tenantId) {
      tenantIdNotifier.value = tenantId;
    }
    return tenantId;
  }

  Future<void> setTenantId(String tenantId) async {
    await _prefs.setString(_prefsKey, tenantId);
    tenantIdNotifier.value = tenantId;
  }
}
