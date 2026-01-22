class WarningItem {
  const WarningItem({
    required this.id,
    required this.title,
    required this.body,
    required this.severity,
    required this.createdAt,
    this.validUntil,
    this.source,
  });

  final String id;
  final String title;
  final String body;
  final WarningSeverity severity;
  final DateTime createdAt;
  final DateTime? validUntil;
  final String? source;

  DateTime get createdAt => publishedAt;
}

enum WarningSeverity {
  info,
  warning,
  critical,
}

extension WarningSeverityLabels on WarningSeverity {
  String get label {
    switch (this) {
      case WarningSeverity.info:
        return 'Info';
      case WarningSeverity.warning:
        return 'Warnung';
      case WarningSeverity.critical:
        return 'Kritisch';
    }
  }
}
