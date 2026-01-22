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

  DateTime get createdAt => publishedAt;

  factory WarningItem.fromJson(Map<String, dynamic> json) {
    final publishedAtValue = json['publishedAt'] ?? json['createdAt'];
    final bodyValue = json['body'] ?? json['description'];
    final severityValue = json['severity'];
    return WarningItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (bodyValue ?? '').toString(),
      severity: _parseSeverity(severityValue),
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

  static WarningSeverity _parseSeverity(dynamic value) {
    final severity = value?.toString();
    switch (severity) {
      case 'minor':
      case 'warning':
        return WarningSeverity.warning;
      case 'major':
      case 'critical':
        return WarningSeverity.critical;
      case 'info':
        return WarningSeverity.info;
      default:
        return WarningSeverity.info;
    }
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
