import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../shared/auth/admin_key_store.dart';
import '../shared/tenant/tenant_store.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      statusCode == null ? message : 'HTTP $statusCode: $message';
}

class ApiClient {
  ApiClient({
    required this.baseUrl,
    required TenantStore tenantStore,
    http.Client? httpClient,
    AdminKeyStore? adminKeyStore,
  })  : _http = httpClient ?? http.Client(),
        _adminKeyStore = adminKeyStore,
        _tenantStore = tenantStore;

  factory ApiClient.platform({
    required TenantStore tenantStore,
    http.Client? httpClient,
    AdminKeyStore? adminKeyStore,
  }) {
    return ApiClient(
      baseUrl: AppConfig.apiBaseUrl,
      tenantStore: tenantStore,
      httpClient: httpClient,
      adminKeyStore: adminKeyStore,
    );
  }

  final String baseUrl;
  final String tenantId;
  final http.Client _http;
  final AdminKeyStore? _adminKeyStore;
  final TenantStore _tenantStore;

  Future<Map<String, dynamic>> getJson(
    String path, {
    bool includeAdminKey = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');

    http.Response res;
    try {
      res = await _http
          .get(uri, headers: _buildHeaders(includeAdminKey: includeAdminKey))
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      throw ApiException('Netzwerkfehler: $e');
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        res.body.isEmpty ? 'Request failed' : res.body,
        statusCode: res.statusCode,
      );
    }

    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw ApiException('Unerwartetes JSON-Format');
    } catch (e) {
      throw ApiException('JSON parse error: $e');
    }
  }

  Future<List<dynamic>> getJsonList(
    String path, {
    bool includeAdminKey = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');

    http.Response res;
    try {
      res = await _http
          .get(uri, headers: _buildHeaders(includeAdminKey: includeAdminKey))
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      throw ApiException('Netzwerkfehler: $e');
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        res.body.isEmpty ? 'Request failed' : res.body,
        statusCode: res.statusCode,
      );
    }

    try {
      final decoded = jsonDecode(res.body);
      if (decoded is List<dynamic>) return decoded;
      throw ApiException('Unerwartetes JSON-Format');
    } catch (e) {
      throw ApiException('JSON parse error: $e');
    }
  }

  Future<dynamic> getJsonFlexible(
    String path, {
    bool includeAdminKey = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');

    http.Response res;
    try {
      res = await _http
          .get(uri, headers: _buildHeaders(includeAdminKey: includeAdminKey))
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      throw ApiException('Netzwerkfehler: $e');
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        res.body.isEmpty ? 'Request failed' : res.body,
        statusCode: res.statusCode,
      );
    }

    try {
      return jsonDecode(res.body);
    } catch (e) {
      throw ApiException('JSON parse error: $e');
    }
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    bool includeAdminKey = false,
    String? adminKeyOverride,
  }) async {
    return _sendJson(
      'POST',
      path,
      body,
      includeAdminKey: includeAdminKey,
      adminKeyOverride: adminKeyOverride,
    );
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> body, {
    bool includeAdminKey = false,
    String? adminKeyOverride,
  }) async {
    return _sendJson(
      'PUT',
      path,
      body,
      includeAdminKey: includeAdminKey,
      adminKeyOverride: adminKeyOverride,
    );
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    bool includeAdminKey = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');

    http.Response res;
    try {
      res = await _http
          .delete(uri, headers: _buildHeaders(includeAdminKey: includeAdminKey))
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      throw ApiException('Netzwerkfehler: $e');
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        res.body.isEmpty ? 'Request failed' : res.body,
        statusCode: res.statusCode,
      );
    }

    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw ApiException('Unerwartetes JSON-Format');
    } catch (e) {
      throw ApiException('JSON parse error: $e');
    }
  }

  Future<Map<String, dynamic>> _sendJson(
    String method,
    String path,
    Map<String, dynamic> body, {
    bool includeAdminKey = false,
    String? adminKeyOverride,
  }) async {
    final uri = Uri.parse('$baseUrl$path');

    http.Response res;
    try {
      res = await _http
          .send(
            http.Request(method, uri)
              ..headers.addAll(
                _buildHeaders(
                  includeJson: true,
                  includeAdminKey: includeAdminKey,
                  adminKeyOverride: adminKeyOverride,
                ),
              )
              ..body = jsonEncode(body),
          )
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      throw ApiException('Netzwerkfehler: $e');
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        res.body.isEmpty ? 'Request failed' : res.body,
        statusCode: res.statusCode,
      );
    }

    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw ApiException('Unerwartetes JSON-Format');
    } catch (e) {
      throw ApiException('JSON parse error: $e');
    }
  }

  Map<String, String> _buildHeaders({
    bool includeJson = false,
    bool includeAdminKey = false,
    String? adminKeyOverride,
  }) {
    final headers = <String, String>{};
    if (includeJson) {
      headers['Content-Type'] = 'application/json';
    }
    final tenantId = _tenantStore.tenantIdNotifier.value;
    if (tenantId.isNotEmpty) {
      headers['X-Tenant'] = tenantId;
    }
    final adminKey = _adminKeyStore?.adminKey;
    if (adminKey != null && adminKey.isNotEmpty) {
      headers['x-admin-key'] = adminKey;
    }
    return headers;
  }
}
