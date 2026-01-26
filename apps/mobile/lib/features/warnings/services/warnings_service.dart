import '../../../api/api_client.dart';
import '../models/warning_item.dart';

class WarningsService {
  WarningsService(this._apiClient);

  final ApiClient _apiClient;

  /// Usage idea for StartFeed:
  /// ```dart
  /// final warnings = await WarningsService(apiClient).getWarnings();
  /// // setState(() => _warnings = warnings);
  /// ```
  Future<List<WarningItem>> getWarnings() async {
    final response = await _apiClient.getJsonFlexible('/warnings');
    final items = _extractList(response);
    return items
        .whereType<Map<String, dynamic>>()
        .map(WarningItem.fromJson)
        .toList();
  }

  Future<WarningItem> createWarning({
    required String title,
    required String body,
    required WarningSeverity severity,
    DateTime? validUntil,
  }) async {
    final data = await _apiClient.postJson('/warnings', {
      'title': title.trim(),
      'body': body.trim(),
      'severity': severity.name,
      if (validUntil != null) 'validUntil': validUntil.toIso8601String(),
    }, includeAuth: true);
    return WarningItem.fromJson(data);
  }

  Future<WarningItem> updateWarning(WarningItem warning) async {
    final data = await _apiClient.putJson('/warnings/${warning.id}', {
      'title': warning.title.trim(),
      'body': warning.body.trim(),
      'severity': warning.severity.name,
      'publishedAt': warning.publishedAt.toIso8601String(),
      if (warning.validUntil != null)
        'validUntil': warning.validUntil!.toIso8601String(),
      if (warning.source != null) 'source': warning.source,
    }, includeAuth: true);
    return WarningItem.fromJson(data);
  }

  Future<void> deleteWarning(String id) async {
    await _apiClient.deleteJson('/warnings/$id', includeAuth: true);
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List<dynamic>) {
      return response;
    }
    if (response is Map<String, dynamic>) {
      final data = response['data'] ?? response['warnings'];
      if (data is List<dynamic>) {
        return data;
      }
    }
    return const <dynamic>[];
  }
}
