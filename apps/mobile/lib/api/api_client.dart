import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
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
    String? Function()? accessTokenProvider,
    Future<bool> Function()? refreshSession,
  })  : _http = httpClient ?? http.Client(),
        _accessTokenProvider = accessTokenProvider,
        _refreshSession = refreshSession,
        _tenantStore = tenantStore;

  factory ApiClient.platform({
    required TenantStore tenantStore,
    http.Client? httpClient,
    String? Function()? accessTokenProvider,
    Future<bool> Function()? refreshSession,
  }) {
    return ApiClient(
      baseUrl: AppConfig.apiBaseUrl,
      tenantStore: tenantStore,
      httpClient: httpClient,
      accessTokenProvider: accessTokenProvider,
      refreshSession: refreshSession,
    );
  }

  final String baseUrl;
  final http.Client _http;
  final String? Function()? _accessTokenProvider;
  final Future<bool> Function()? _refreshSession;
  final TenantStore _tenantStore;
  static const Duration _requestTimeout = Duration(seconds: 10);
  Future<bool>? _refreshSessionFuture;

  String resolveTenantId() => _tenantStore.resolveTenantId();

  Map<String, bool> debugHeaderPresence() {
    final headers = _buildHeaders();
    return {
      'X-TENANT': headers.containsKey('X-TENANT'),
      'X-SITE-KEY': headers.containsKey('X-SITE-KEY'),
    };
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    bool allowAuthRetry = true,
    bool includeAuth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await _sendWithAuthRetry(
      method: 'GET',
      uri: uri,
      allowAuthRetry: allowAuthRetry,
      buildHeaders: () => _buildHeaders(
        includeAuth: includeAuth,
      ),
      send: (headers) => _http
          .get(uri, headers: headers)
          .timeout(_requestTimeout),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        _resolveErrorMessage(res),
        statusCode: res.statusCode,
      );
    }

    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw ApiException('Unerwartetes JSON-Format');
    } on FormatException catch (e, stack) {
      _logException('FormatException', e, stack);
      throw ApiException('JSON parse error: $e');
    } catch (e, stack) {
      _logException('Exception', e, stack);
      throw ApiException('JSON parse error: $e');
    }
  }

  Future<List<dynamic>> getJsonList(
    String path, {
    bool allowAuthRetry = true,
    bool includeAuth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await _sendWithAuthRetry(
      method: 'GET',
      uri: uri,
      allowAuthRetry: allowAuthRetry,
      buildHeaders: () => _buildHeaders(
        includeAuth: includeAuth,
      ),
      send: (headers) => _http
          .get(uri, headers: headers)
          .timeout(_requestTimeout),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        _resolveErrorMessage(res),
        statusCode: res.statusCode,
      );
    }

    try {
      final decoded = jsonDecode(res.body);
      if (decoded is List<dynamic>) return decoded;
      throw ApiException('Unerwartetes JSON-Format');
    } on FormatException catch (e, stack) {
      _logException('FormatException', e, stack);
      throw ApiException('JSON parse error: $e');
    } catch (e, stack) {
      _logException('Exception', e, stack);
      throw ApiException('JSON parse error: $e');
    }
  }

  Future<dynamic> getJsonFlexible(
    String path, {
    bool allowAuthRetry = true,
    bool includeAuth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await _sendWithAuthRetry(
      method: 'GET',
      uri: uri,
      allowAuthRetry: allowAuthRetry,
      buildHeaders: () => _buildHeaders(
        includeAuth: includeAuth,
      ),
      send: (headers) => _http
          .get(uri, headers: headers)
          .timeout(_requestTimeout),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        _resolveErrorMessage(res),
        statusCode: res.statusCode,
      );
    }

    try {
      return jsonDecode(res.body);
    } on FormatException catch (e, stack) {
      _logException('FormatException', e, stack);
      throw ApiException('JSON parse error: $e');
    } catch (e, stack) {
      _logException('Exception', e, stack);
      throw ApiException('JSON parse error: $e');
    }
  }

  Future<ApiResponse<dynamic>> getJsonFlexibleWithResponse(
    String path, {
    bool allowAuthRetry = true,
    bool includeAuth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await _sendWithAuthRetry(
      method: 'GET',
      uri: uri,
      allowAuthRetry: allowAuthRetry,
      buildHeaders: () => _buildHeaders(
        includeAuth: includeAuth,
      ),
      send: (headers) => _http
          .get(uri, headers: headers)
          .timeout(_requestTimeout),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        _resolveErrorMessage(res),
        statusCode: res.statusCode,
      );
    }

    try {
      return ApiResponse<dynamic>(
        data: jsonDecode(res.body),
        statusCode: res.statusCode,
        uri: uri,
      );
    } on FormatException catch (e, stack) {
      _logException('FormatException', e, stack);
      throw ApiException('JSON parse error: $e');
    } catch (e, stack) {
      _logException('Exception', e, stack);
      throw ApiException('JSON parse error: $e');
    }
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    bool allowAuthRetry = true,
    bool includeAuth = false,
  }) async {
    return _sendJson(
      'POST',
      path,
      body,
      allowAuthRetry: allowAuthRetry,
      includeAuth: includeAuth,
    );
  }

  Future<Map<String, dynamic>> postMultipartFile(
    String path, {
    required String fieldName,
    required List<int> bytes,
    required String filename,
    Map<String, String>? fields,
    bool allowAuthRetry = false,
    bool includeAuth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await _sendWithAuthRetry(
      method: 'POST',
      uri: uri,
      allowAuthRetry: allowAuthRetry,
      buildHeaders: () => _buildHeaders(
        includeAuth: includeAuth,
      ),
      send: (headers) async {
        final request = http.MultipartRequest('POST', uri);
        request.headers.addAll(headers);
        if (fields != null) {
          request.fields.addAll(fields);
        }
        request.files.add(
          http.MultipartFile.fromBytes(fieldName, bytes, filename: filename),
        );
        final streamed = await request.send();
        return http.Response.fromStream(streamed);
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        _resolveErrorMessage(res),
        statusCode: res.statusCode,
      );
    }

    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw ApiException('Unerwartetes JSON-Format');
    } on FormatException catch (e, stack) {
      _logException('FormatException', e, stack);
      throw ApiException('JSON parse error: $e');
    } catch (e, stack) {
      _logException('Exception', e, stack);
      throw ApiException('JSON parse error: $e');
    }
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> body, {
    bool allowAuthRetry = true,
    bool includeAuth = false,
  }) async {
    return _sendJson(
      'PUT',
      path,
      body,
      allowAuthRetry: allowAuthRetry,
      includeAuth: includeAuth,
    );
  }

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body, {
    bool allowAuthRetry = true,
    bool includeAuth = false,
  }) async {
    return _sendJson(
      'PATCH',
      path,
      body,
      allowAuthRetry: allowAuthRetry,
      includeAuth: includeAuth,
    );
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    bool allowAuthRetry = true,
    bool includeAuth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await _sendWithAuthRetry(
      method: 'DELETE',
      uri: uri,
      allowAuthRetry: allowAuthRetry,
      buildHeaders: () => _buildHeaders(
        includeAuth: includeAuth,
      ),
      send: (headers) => _http
          .delete(uri, headers: headers)
          .timeout(_requestTimeout),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        _resolveErrorMessage(res),
        statusCode: res.statusCode,
      );
    }

    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw ApiException('Unerwartetes JSON-Format');
    } on FormatException catch (e, stack) {
      _logException('FormatException', e, stack);
      throw ApiException('JSON parse error: $e');
    } catch (e, stack) {
      _logException('Exception', e, stack);
      throw ApiException('JSON parse error: $e');
    }
  }

  Future<dynamic> fetchPosts({required String type}) {
    return getJsonFlexible(
      '/posts?type=$type',
      includeAuth: true,
    );
  }

  Future<Map<String, dynamic>> createPost(Map<String, dynamic> payload) {
    return postJson(
      '/posts',
      payload,
      includeAuth: true,
    );
  }

  Future<Map<String, dynamic>> updatePost(
    String id,
    Map<String, dynamic> payload,
  ) {
    return patchJson(
      '/posts/$id',
      payload,
      includeAuth: true,
    );
  }

  Future<Map<String, dynamic>> deletePost(String id) {
    return deleteJson(
      '/posts/$id',
      includeAuth: true,
    );
  }

  Future<Map<String, dynamic>> reportPost(String id) {
    return postJson(
      '/posts/$id/report',
      const {},
      includeAuth: true,
    );
  }

  Future<Map<String, dynamic>> _sendJson(
    String method,
    String path,
    Map<String, dynamic> body, {
    bool allowAuthRetry = true,
    bool includeAuth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await _sendWithAuthRetry(
      method: method,
      uri: uri,
      allowAuthRetry: allowAuthRetry,
      buildHeaders: () => _buildHeaders(
        includeJson: true,
        includeAuth: includeAuth,
      ),
      send: (headers) => _http
          .send(
            http.Request(method, uri)
              ..headers.addAll(headers)
              ..body = jsonEncode(body),
          )
          .then(http.Response.fromStream)
          .timeout(_requestTimeout),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        _resolveErrorMessage(res),
        statusCode: res.statusCode,
      );
    }

    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw ApiException('Unerwartetes JSON-Format');
    } on FormatException catch (e, stack) {
      _logException('FormatException', e, stack);
      throw ApiException('JSON parse error: $e');
    } catch (e, stack) {
      _logException('Exception', e, stack);
      throw ApiException('JSON parse error: $e');
    }
  }

  Map<String, String> _buildHeaders({
    bool includeJson = false,
    bool includeAuth = false,
  }) {
    final headers = <String, String>{};
    if (includeJson) {
      headers['Content-Type'] = 'application/json';
    }
    final tenantId = _tenantStore.resolveTenantId();
    headers['X-TENANT'] = tenantId;
    headers['X-SITE-KEY'] = AppConfig.siteKey;
    if (includeAuth) {
      final accessToken = _accessTokenProvider?.call();
      final trimmedToken = accessToken?.trim();
      if (trimmedToken != null && trimmedToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $trimmedToken';
      }
    }
    return headers;
  }

  String _resolveErrorMessage(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return 'Sitzung abgelaufen oder keine Berechtigung. Bitte erneut anmelden.';
    }
    if (response.body.isEmpty) {
      return 'Request failed';
    }
    return response.body;
  }

  Future<http.Response> _sendWithAuthRetry({
    required String method,
    required Uri uri,
    required bool allowAuthRetry,
    required Map<String, String> Function() buildHeaders,
    required Future<http.Response> Function(Map<String, String> headers) send,
  }) async {
    var headers = buildHeaders();
    _logRequest(method, uri, headers);
    var res = await _performRequest(() => send(headers));
    if (_shouldAttemptRefresh(headers, allowAuthRetry) && res.statusCode == 401) {
      final refreshed = await _attemptRefresh();
      if (refreshed) {
        headers = buildHeaders();
        _logRequest('$method (retry)', uri, headers);
        res = await _performRequest(() => send(headers));
      }
    }
    _logResponse(res);
    return res;
  }

  bool _shouldAttemptRefresh(
    Map<String, String> headers,
    bool allowAuthRetry,
  ) {
    if (!allowAuthRetry || _refreshSession == null) {
      return false;
    }
    return headers.containsKey('Authorization');
  }

  Future<bool> _attemptRefresh() async {
    if (_refreshSession == null) {
      return false;
    }
    if (_refreshSessionFuture != null) {
      return _refreshSessionFuture!;
    }
    _refreshSessionFuture = _refreshSession!();
    try {
      return await _refreshSessionFuture!;
    } catch (_) {
      return false;
    } finally {
      _refreshSessionFuture = null;
    }
  }

  Future<http.Response> _performRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request();
    } on SocketException catch (e, stack) {
      _logException('SocketException', e, stack);
      throw ApiException(
        'Backend nicht erreichbar. Bitte Verbindung prüfen und erneut versuchen.',
      );
    } on TimeoutException catch (e, stack) {
      _logException('TimeoutException', e, stack);
      throw ApiException(
        'Zeitüberschreitung beim Backend. Bitte erneut versuchen.',
      );
    } on HttpException catch (e, stack) {
      _logException('HttpException', e, stack);
      throw ApiException('HTTP-Fehler: $e');
    } on FormatException catch (e, stack) {
      _logException('FormatException', e, stack);
      throw ApiException('Antwortformat-Fehler: $e');
    } on Exception catch (e, stack) {
      _logException('Exception', e, stack);
      throw ApiException('Netzwerkfehler: $e');
    }
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

  void _logResponse(http.Response response) {
    if (!kDebugMode) {
      return;
    }
    final bodyPreview = _truncateBody(response.body);
    debugPrint('API RESP ${response.statusCode} $bodyPreview');
  }

  void _logException(String type, Object error, StackTrace stack) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('API EXCEPTION $type $error');
    debugPrint(stack.toString());
  }

  String _truncateBody(String body) {
    if (body.isEmpty) {
      return '<empty>';
    }
    if (body.length <= 500) {
      return body;
    }
    return '${body.substring(0, 500)}...';
  }
}
