import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TenantStore {
  TenantStore(this._prefs, {String defaultTenantId = 'demo'})
      : _defaultTenantId = defaultTenantId,
        _lastKnownTenantId = defaultTenantId,
        tenantIdNotifier = ValueNotifier<String>(defaultTenantId);

  static const _prefsKey = 'tenant_id';

  final SharedPreferences _prefs;
  final String _defaultTenantId;
  String _lastKnownTenantId;
  final ValueNotifier<String> tenantIdNotifier;

  Future<String> getTenantId() async {
    final stored = _prefs.getString(_prefsKey);
    final tenantId = stored != null && stored.isNotEmpty
        ? stored
        : _defaultTenantId;
    _lastKnownTenantId = tenantId;
    if (tenantIdNotifier.value != tenantId) {
      tenantIdNotifier.value = tenantId;
    }
    return tenantId;
  }

  Future<void> setTenantId(String tenantId) async {
    await _prefs.setString(_prefsKey, tenantId);
    _lastKnownTenantId = tenantId;
    tenantIdNotifier.value = tenantId;
  }

  String resolveTenantId({bool allowDebugFallback = true}) {
    final current = tenantIdNotifier.value.trim();
    if (current.isNotEmpty) {
      _lastKnownTenantId = current;
      return current;
    }

    final cached = _lastKnownTenantId.trim();
    if (cached.isNotEmpty) {
      return cached;
    }

    if (allowDebugFallback && kDebugMode) {
      return 'hilders';
    }

    return _defaultTenantId;
  }
}
