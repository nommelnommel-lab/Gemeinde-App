import 'package:flutter/foundation.dart';

import '../../../api/api_client.dart';
import '../../../shared/auth/activation_code_normalizer.dart';
import '../models/auth_models.dart';

class AuthService {
  AuthService(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthResponse> activate({
    required String activationCode,
    required String postalCode,
    required String houseNumber,
    required String email,
    required String password,
  }) async {
    final normalizedActivationCode = normalizeActivationCode(activationCode);
    if (kDebugMode) {
      final tenantId = _apiClient.resolveTenantId();
      final containsNonAscii = activationCode.runes.any((rune) => rune > 127);
      final headerPresence = _apiClient.debugHeaderPresence();
      debugPrint(
        'activate tenant=$tenantId '
        'activationCodeLength=${normalizedActivationCode.length} '
        'activationCodeContainsNonAscii=$containsNonAscii',
      );
      debugPrint(
        'activate POST ${_apiClient.baseUrl}/api/auth/activate '
        'headers: tenant=${headerPresence['X-TENANT']} '
        'siteKey=${headerPresence['X-SITE-KEY']} '
        'codeNormLen=${normalizedActivationCode.length}',
      );
    }
    final response = await _apiClient.postJson(
      '/api/auth/activate',
      {
        'activationCode': normalizedActivationCode,
        'postalCode': postalCode,
        'houseNumber': houseNumber,
        'email': email,
        'password': password,
      },
    );
    return AuthResponse.fromJson(response);
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.postJson(
      '/api/auth/login',
      {
        'email': email,
        'password': password,
      },
    );
    return AuthResponse.fromJson(response);
  }

  Future<AuthResponse> refresh({
    required String refreshToken,
  }) async {
    final response = await _apiClient.postJson(
      '/api/auth/refresh',
      {'refreshToken': refreshToken},
    );
    return AuthResponse.fromJson(response);
  }

  Future<void> logout({
    required String refreshToken,
  }) async {
    await _apiClient.postJson(
      '/api/auth/logout',
      {'refreshToken': refreshToken},
    );
  }
}
