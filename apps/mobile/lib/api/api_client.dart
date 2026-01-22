import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../shared/auth/admin_key_store.dart';

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
    http.Client? httpClient,
    AdminKeyStore? adminKeyStore,
  })  : _http = httpClient ?? http.Client(),
        _adminKeyStore = adminKeyStore;

  factory ApiClient.platform({
    http.Client? httpClient,
    AdminKeyStore? adminKeyStore,
  }) {
    return ApiClient(
      baseUrl: AppConfig.apiBaseUrl,
      httpClient: httpClient,
      adminKeyStore: adminKeyStore,
    );
  }

  final String baseUrl;
  final http.Client _http;
  final AdminKeyStore? _adminKeyStore;

  Future<Map<String, dynamic>> getJson(String path) async {
    final uri = Uri.parse('$baseUrl$path');

    http.Response res;
    try {
      res = await _http
          .get(uri, headers: _buildHeaders())
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

  Future<List<dynamic>> getJsonList(String path) async {
    final uri = Uri.parse('$baseUrl$path');

    http.Response res;
    try {
      res = await _http
          .get(uri, headers: _buildHeaders())
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

  Future<dynamic> getJsonFlexible(String path) async {
    final uri = Uri.parse('$baseUrl$path');

    http.Response res;
    try {
      res = await _http
          .get(uri, headers: _buildHeaders())
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
    Map<String, dynamic> body,
  ) async {
    return _sendJson('POST', path, body);
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    return _sendJson('PUT', path, body);
  }

  Future<Map<String, dynamic>> deleteJson(String path) async {
    final uri = Uri.parse('$baseUrl$path');

    http.Response res;
    try {
      res = await _http
          .delete(uri, headers: _buildHeaders())
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
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');

    http.Response res;
    try {
      res = await _http
          .send(
            http.Request(method, uri)
              ..headers.addAll(_buildHeaders(includeJson: true))
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

  Map<String, String> _buildHeaders({bool includeJson = false}) {
    final headers = <String, String>{};
    if (includeJson) {
      headers['Content-Type'] = 'application/json';
    }
    final adminKey = _adminKeyStore?.adminKey;
    if (adminKey != null && adminKey.isNotEmpty) {
      headers['x-admin-key'] = adminKey;
    }
    return headers;
  }
}
