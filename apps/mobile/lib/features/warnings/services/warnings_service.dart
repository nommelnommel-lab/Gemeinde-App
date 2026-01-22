import '../models/warning_item.dart';

class WarningsService {
  /// Usage idea for StartFeed:
  /// ```dart
  /// final warnings = await WarningsService().getWarnings();
  /// // setState(() => _warnings = warnings);
  /// ```
  Future<List<WarningItem>> getWarnings() async {
    return List<WarningItem>.unmodifiable(_stubWarnings);
  }
}

final List<WarningItem> _stubWarnings = [
  WarningItem(
    id: 'warn-1',
    title: 'Gewitterwarnung',
    message: 'Bitte vermeiden Sie Aufenthalte im Freien am Abend.',
    severity: WarningSeverity.warning,
    issuedAt: DateTime(2024, 9, 15, 18, 0),
  ),
  WarningItem(
    id: 'warn-2',
    title: 'Trinkwasser-Hinweis',
    message: 'Das Wasser kann kurzzeitig nach Chlor riechen.',
    severity: WarningSeverity.info,
    issuedAt: DateTime(2024, 9, 13, 9, 30),
  ),
  WarningItem(
    id: 'warn-3',
    title: 'Stromausfall in Teilgebieten',
    message: 'Die Entstörung ist im Gange. Updates folgen.',
    severity: WarningSeverity.critical,
    issuedAt: DateTime(2024, 9, 11, 6, 45),
  ),
];
