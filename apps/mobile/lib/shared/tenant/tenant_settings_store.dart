import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/verwaltung/services/tenant_config_service.dart';
import '../tenant/tenant_store.dart';
import 'tenant_settings.dart';

class TenantSettingsStore extends ChangeNotifier {
  TenantSettingsStore({
    required SharedPreferences prefs,
    required TenantConfigService tenantConfigService,
    required TenantStore tenantStore,
  })  : _prefs = prefs,
        _tenantConfigService = tenantConfigService,
        _tenantStore = tenantStore {
    _tenantStore.tenantIdNotifier.addListener(_onTenantChanged);
  }

  final SharedPreferences _prefs;
  final TenantConfigService _tenantConfigService;
  final TenantStore _tenantStore;

  TenantSettings? _settings;
  bool _isLoading = false;
  String? _error;

  TenantSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasSettings => _settings != null;

  String get _cacheKey => 'tenant_settings_cache_${_tenantStore.tenantIdNotifier.value}';

  Future<void> bootstrap({bool forceRefresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final cached = _loadCachedSettings();

    try {
      final raw = await _tenantConfigService.getTenantConfigRaw();
      final parsed = TenantSettings.fromJson(raw);
      _settings = parsed;
      await _cacheSettings(parsed);
    } catch (error) {
      if (cached != null) {
        _settings = cached;
      } else {
        _error = error.toString();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isFeatureEnabled(String key) => _settings?.isFeatureEnabled(key) ?? true;

  @override
  void dispose() {
    _tenantStore.tenantIdNotifier.removeListener(_onTenantChanged);
    super.dispose();
  }

  void _onTenantChanged() {
    bootstrap(forceRefresh: true);
  }

  TenantSettings? _loadCachedSettings() {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return TenantSettings.fromJson(decoded);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _cacheSettings(TenantSettings settings) async {
    try {
      await _prefs.setString(_cacheKey, jsonEncode(settings.toJson()));
    } catch (_) {}
  }
}
