import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

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

class ApiResponse<T> {
  ApiResponse({
    required this.data,
    required this.statusCode,
    required this.uri,
  });

  final T data;
  final int statusCode;
  final Uri uri;
}

class ApiClient {
  ApiClient({
    required this.baseUrl,
    required TenantStore tenantStore,
    http.Client? httpClient,
    AdminKeyStore? adminKeyStore,
    String? Function()? accessTokenProvider,
  })  : _http = httpClient ?? http.Client(),
        _adminKeyStore = adminKeyStore,
        _accessTokenProvider = accessTokenProvider,
        _tenantStore = tenantStore;

  factory ApiClient.platform({
    required TenantStore tenantStore,
    http.Client? httpClient,
    AdminKeyStore? adminKeyStore,
    String? Function()? accessTokenProvider,
  }) {
    return ApiClient(
      baseUrl: AppConfig.apiBaseUrl,
      tenantStore: tenantStore,
      httpClient: httpClient,
      adminKeyStore: adminKeyStore,
      accessTokenProvider: accessTokenProvider,
    );
  }

  final String baseUrl;
  final http.Client _http;
  final AdminKeyStore? _adminKeyStore;
  final String? Function()? _accessTokenProvider;
  final TenantStore _tenantStore;

  Future<Map<String, dynamic>> getJson(
    String path, {
    bool includeAdminKey = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = _buildHeaders(includeAdminKey: includeAdminKey);
    _logRequest('GET', uri, headers);

    http.Response res;
    try {
      res =
          await _http.get(uri, headers: headers).timeout(const Duration(seconds: 5));
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
    final headers = _buildHeaders(includeAdminKey: includeAdminKey);
    _logRequest('GET', uri, headers);

    http.Response res;
    try {
      res =
          await _http.get(uri, headers: headers).timeout(const Duration(seconds: 5));
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
    final headers = _buildHeaders(includeAdminKey: includeAdminKey);
    _logRequest('GET', uri, headers);

    http.Response res;
    try {
      res =
          await _http.get(uri, headers: headers).timeout(const Duration(seconds: 5));
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

  Future<ApiResponse<dynamic>> getJsonFlexibleWithResponse(
    String path, {
    bool includeAdminKey = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = _buildHeaders(includeAdminKey: includeAdminKey);
    _logRequest('GET', uri, headers);

    http.Response res;
    try {
      res =
          await _http.get(uri, headers: headers).timeout(const Duration(seconds: 5));
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
      return ApiResponse<dynamic>(
        data: jsonDecode(res.body),
        statusCode: res.statusCode,
        uri: uri,
      );
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
    final headers = _buildHeaders(includeAdminKey: includeAdminKey);
    _logRequest('DELETE', uri, headers);

    http.Response res;
    try {
      res = await _http
          .delete(uri, headers: headers)
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
    final headers = _buildHeaders(
      includeJson: true,
      includeAdminKey: includeAdminKey,
      adminKeyOverride: adminKeyOverride,
    );
    _logRequest(method, uri, headers);

    http.Response res;
    try {
      res = await _http
          .send(
            http.Request(method, uri)
              ..headers.addAll(headers)
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
    headers['X-TENANT'] = _tenantStore.tenantIdNotifier.value;
    headers['X-SITE-KEY'] = AppConfig.siteKey;
    final tenantId = _tenantStore.tenantIdNotifier.value;
    final adminKey =
        _adminKeyStore?.getAdminKey(adminKeyOverride ?? tenantId);
    if (adminKey != null && adminKey.isNotEmpty) {
      headers['x-admin-key'] = adminKey;
    }
    final accessToken = _accessTokenProvider?.call();
    final trimmedToken = accessToken?.trim();
    if (trimmedToken != null && trimmedToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $trimmedToken';
    }
    return headers;
  }

  void _logRequest(String method, Uri uri, Map<String, String> headers) {
    if (!kDebugMode) {
      return;
    }
    final hasTenant = headers.containsKey('X-TENANT');
    final hasSiteKey = headers.containsKey('X-SITE-KEY');
    final siteKeyValue = headers['X-SITE-KEY'];
    final siteKeyPreview = siteKeyValue == null || siteKeyValue.isEmpty
        ? 'missing'
        : '${siteKeyValue.substring(0, siteKeyValue.length < 4 ? siteKeyValue.length : 4)}***';
    debugPrint(
      'API $method $uri headers: tenant=$hasTenant siteKey=$hasSiteKey siteKeyPreview=$siteKeyPreview',
    );
  }
}
