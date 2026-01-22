class WarningItem {
  const WarningItem({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.issuedAt,
  });

  final String id;
  final String title;
  final String message;
  final WarningSeverity severity;
  final DateTime issuedAt;
}

enum WarningSeverity {
  info,
  warning,
  critical,
}
