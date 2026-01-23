import '../../../api/api_client.dart';
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
    final response = await _apiClient.postJson(
      '/api/auth/activate',
      {
        'activationCode': activationCode,
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
