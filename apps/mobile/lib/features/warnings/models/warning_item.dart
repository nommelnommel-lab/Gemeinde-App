class WarningItem {
  const WarningItem({
    required this.id,
    required this.title,
    required this.body,
    required this.severity,
    required this.publishedAt,
    this.validUntil,
    this.source,
  });

  final String id;
  final String title;
  final String body;
  final WarningSeverity severity;
  final DateTime publishedAt;
  final DateTime? validUntil;
  final String? source;

  factory WarningItem.fromJson(Map<String, dynamic> json) {
    final publishedAtValue = json['publishedAt'] ?? json['createdAt'];
    return WarningItem(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      severity: WarningSeverity.values.firstWhere(
        (severity) => severity.name == json['severity'],
        orElse: () => WarningSeverity.info,
      ),
      publishedAt: _parseDateTime(publishedAtValue),
      validUntil: _parseOptionalDateTime(json['validUntil']),
      source: json['source'] as String?,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    throw FormatException('Ungültiges Datum für Warnung: $value');
  }

  static DateTime? _parseOptionalDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    return _parseDateTime(value);
  }
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
