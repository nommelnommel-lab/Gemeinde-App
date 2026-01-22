import 'package:flutter/material.dart';

import '../models/warning_item.dart';

class WarningSeverityChip extends StatelessWidget {
  const WarningSeverityChip({super.key, required this.severity});

  final WarningSeverity severity;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(severity);
    return Chip(
      label: Text(severity.label),
      backgroundColor: color.withOpacity(0.12),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      side: BorderSide(color: color.withOpacity(0.4)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Color _severityColor(WarningSeverity severity) {
    switch (severity) {
      case WarningSeverity.info:
        return Colors.blue;
      case WarningSeverity.warning:
        return Colors.orange;
      case WarningSeverity.critical:
        return Colors.red;
    }
  }
}
