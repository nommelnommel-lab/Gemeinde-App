import 'package:shared_preferences/shared_preferences.dart';

class AdminKeyStore {
  AdminKeyStore(this._prefs);

  static const String _storageKey = 'admin_key';

  final SharedPreferences _prefs;

  String? get adminKey => _prefs.getString(_storageKey);

  Future<void> setAdminKey(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await _prefs.remove(_storageKey);
    } else {
      await _prefs.setString(_storageKey, trimmed);
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_storageKey);
  }
}
