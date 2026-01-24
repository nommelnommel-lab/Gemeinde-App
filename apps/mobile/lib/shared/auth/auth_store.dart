import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/models/auth_models.dart';
import '../../features/auth/services/auth_service.dart';

class AuthStore extends ChangeNotifier {
  AuthStore({
    required FlutterSecureStorage secureStorage,
    required AuthService authService,
  })  : _secureStorage = secureStorage,
        _authService = authService;

  static const _refreshTokenKey = 'refreshToken';
  static const _userKey = 'authUser';

  final FlutterSecureStorage _secureStorage;
  final AuthService _authService;

  AuthUser? _user;
  String? _accessToken;
  String? _refreshToken;
  Future<bool>? _refreshSessionFuture;
  bool _isLoading = false;
  String? _lastError;

  AuthUser? get user => _user;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get isAuthenticated => _accessToken != null;

  Future<void> bootstrap() async {
    if (_isLoading) return;
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final storedUser = await _secureStorage.read(key: _userKey);
      if (storedUser != null && storedUser.isNotEmpty) {
        final decoded = jsonDecode(storedUser);
        if (decoded is Map<String, dynamic>) {
          _user = AuthUser.fromJson(decoded);
        }
      }
    } catch (_) {}

    _refreshToken = await _loadRefreshToken();
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await _authService.refresh(
        refreshToken: _refreshToken!,
      );
      await _applyAuthResponse(response);
      _lastError = null;
    } catch (error) {
      await _clearSession();
      _lastError = error.toString();
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
      () => _authService.activate(
        activationCode: activationCode,
        postalCode: postalCode,
        houseNumber: houseNumber,
        email: email,
        password: password,
      ),
    );
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _authenticate(
      () => _authService.login(
        email: email,
        password: password,
      ),
    );
  }

  Future<void> logout() async {
    if (_isLoading) return;
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final token = _refreshToken ?? await _loadRefreshToken();
      if (token != null && token.isNotEmpty) {
        try {
          await _authService.logout(refreshToken: token);
        } catch (_) {}
      }
      await _clearSession();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> refreshSession() async {
    if (_refreshSessionFuture != null) {
      return _refreshSessionFuture!;
    }
    _refreshSessionFuture = _refreshSessionInternal();
    try {
      return await _refreshSessionFuture!;
    } finally {
      _refreshSessionFuture = null;
    }
  }

  Future<void> _authenticate(Future<AuthResponse> Function() action) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await action();
      await _applyAuthResponse(response);
    } catch (error) {
      _lastError = error.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _applyAuthResponse(AuthResponse response) async {
    _accessToken = response.accessToken;
    _refreshToken = response.refreshToken;
    _user = response.user;
    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      await _secureStorage.write(key: _refreshTokenKey, value: _refreshToken);
    }
    await _secureStorage.write(
      key: _userKey,
      value: jsonEncode(_user?.toJson() ?? {}),
    );
  }

  Future<String?> _loadRefreshToken() async {
    final token = await _secureStorage.read(key: _refreshTokenKey);
    if (token != null && token.isNotEmpty) {
      _refreshToken = token;
      return token;
    }
    _refreshToken = null;
    return null;
  }

  Future<bool> _refreshSessionInternal() async {
    final token = _refreshToken ?? await _loadRefreshToken();
    if (token == null || token.isEmpty) {
      await _clearSession();
      notifyListeners();
      return false;
    }
    try {
      final response = await _authService.refresh(refreshToken: token);
      await _applyAuthResponse(response);
      notifyListeners();
      return true;
    } catch (_) {
      await _clearSession();
      notifyListeners();
      return false;
    }
  }

  Future<void> _clearSession() async {
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userKey);
    _refreshToken = null;
    _accessToken = null;
    _user = null;
  }
}
