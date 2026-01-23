import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../api/api_client.dart';
import 'auth_user.dart';

class AuthStore extends ChangeNotifier {
  AuthStore({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  static const _refreshTokenKey = 'auth_refresh_token';

  final FlutterSecureStorage _secureStorage;
  ApiClient? _apiClient;

  AuthUser? _user;
  String? _accessToken;
  bool _isLoading = false;
  String? _error;

  AuthUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _accessToken != null;

  void attachApiClient(ApiClient apiClient) {
    _apiClient = apiClient;
  }

  Future<void> bootstrap() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    final token = await _secureStorage.read(key: _refreshTokenKey);
    if (token == null || token.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await _apiClient!.postJson(
        '/api/auth/refresh',
        {'refreshToken': token},
      );
      _accessToken = response['accessToken'] as String?;
      final newRefreshToken = response['refreshToken'] as String?;
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _secureStorage.write(key: _refreshTokenKey, value: newRefreshToken);
      }
    } catch (error) {
      await _secureStorage.delete(key: _refreshTokenKey);
      _accessToken = null;
      _user = null;
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> activate({
    required String activationCode,
    required String postalCode,
    required String houseNumber,
    required String email,
    required String password,
  }) async {
    await _authenticate(
      '/api/auth/activate',
      {
        'activationCode': activationCode,
        'postalCode': postalCode,
        'houseNumber': houseNumber,
        'email': email,
        'password': password,
      },
    );
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _authenticate(
      '/api/auth/login',
      {
        'email': email,
        'password': password,
      },
    );
  }

  Future<void> logout() async {
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _apiClient?.postJson(
          '/api/auth/logout',
          {'refreshToken': refreshToken},
        );
      } catch (_) {}
    }
    await _secureStorage.delete(key: _refreshTokenKey);
    _accessToken = null;
    _user = null;
    notifyListeners();
  }

  Future<void> _authenticate(String path, Map<String, dynamic> payload) async {
    if (_apiClient == null) {
      throw StateError('ApiClient nicht initialisiert');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient!.postJson(path, payload);
      _accessToken = response['accessToken'] as String?;
      final refreshToken = response['refreshToken'] as String?;
      final userJson = response['user'] as Map<String, dynamic>?;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      }
      if (userJson != null) {
        _user = AuthUser.fromJson(userJson);
      }
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
