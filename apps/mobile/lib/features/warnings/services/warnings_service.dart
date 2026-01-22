import '../../../api/api_client.dart';
import '../models/warning_item.dart';

class WarningsService {
  WarningsService([this._apiClient]);

  final ApiClient? _apiClient;
  final List<WarningItem> _warningStore = List<WarningItem>.from(_stubWarnings);

  /// Usage idea for StartFeed:
  /// ```dart
  /// final warnings = await WarningsService().getWarnings();
  /// // setState(() => _warnings = warnings);
  /// ```
  Future<List<WarningItem>> getWarnings() async {
    // TODO: replace with real API call once endpoint is available.
    // Example:
    // final response = await _apiClient?.getJson('/warnings');
    // parse response into WarningItem list.
    return List<WarningItem>.unmodifiable(_warningStore);
  }

  Future<WarningItem> createWarning({
    required String title,
    required String body,
    required WarningSeverity severity,
    DateTime? validUntil,
  }) async {
    final now = DateTime.now();
    final warning = WarningItem(
      id: 'warn-${now.microsecondsSinceEpoch}',
      title: title,
      body: body,
      severity: severity,
      publishedAt: now,
      validUntil: validUntil,
    );
    _warningStore.insert(0, warning);
    return warning;
  }

  Future<WarningItem> updateWarning(WarningItem warning) async {
    final index = _warningStore.indexWhere((item) => item.id == warning.id);
    if (index == -1) {
      throw StateError('Warnung nicht gefunden.');
    }
    _warningStore[index] = warning;
    return warning;
  }

  Future<void> deleteWarning(String id) async {
    _warningStore.removeWhere((item) => item.id == id);
  }
}

final List<WarningItem> _stubWarnings = [
  WarningItem(
    id: 'warn-1',
    title: 'Gewitterwarnung',
    body: 'Bitte vermeiden Sie Aufenthalte im Freien am Abend.',
    severity: WarningSeverity.warning,
    publishedAt: DateTime(2024, 9, 15, 18, 0),
    validUntil: DateTime(2024, 9, 16, 2, 0),
    source: 'Deutscher Wetterdienst',
  ),
  WarningItem(
    id: 'warn-2',
    title: 'Trinkwasser-Hinweis',
    body: 'Das Wasser kann kurzzeitig nach Chlor riechen.',
    severity: WarningSeverity.info,
    publishedAt: DateTime(2024, 9, 13, 9, 30),
    validUntil: DateTime(2024, 9, 18, 12, 0),
    source: 'Stadtwerke Musterhausen',
  ),
  WarningItem(
    id: 'warn-3',
    title: 'Stromausfall in Teilgebieten',
    body: 'Die Entstörung ist im Gange. Updates folgen.',
    severity: WarningSeverity.critical,
    publishedAt: DateTime(2024, 9, 11, 6, 45),
    source: 'Energieversorgung Gemeinde',
  ),
  WarningItem(
    id: 'warn-4',
    title: 'Straßensperrung Bahnhofstraße',
    body: 'Die Bahnhofstraße ist wegen Bauarbeiten gesperrt. Bitte Umleitung beachten.',
    severity: WarningSeverity.warning,
    publishedAt: DateTime(2024, 9, 10, 7, 15),
    validUntil: DateTime(2024, 9, 30, 18, 0),
    source: 'Bauamt',
  ),
];
