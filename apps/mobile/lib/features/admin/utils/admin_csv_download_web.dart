// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<String?> downloadCsv(String filename, String contents) async {
  final bytes = html.Blob([contents], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(bytes);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  return filename;
}
