import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openExternalLink(
  BuildContext context,
  String rawUrl,
) async {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) {
    _showMessage(context, 'Kein Link hinterlegt.');
    return;
  }
  Uri? uri = Uri.tryParse(trimmed);
  if (uri == null || (!uri.hasScheme && !trimmed.contains('://'))) {
    uri = Uri.tryParse('https://$trimmed');
  }
  if (uri == null || !['http', 'https'].contains(uri.scheme)) {
    _showMessage(context, 'Ungültiger Link.');
    return;
  }
  final success = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );
  if (!success) {
    _showMessage(context, 'Link konnte nicht geöffnet werden.');
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
