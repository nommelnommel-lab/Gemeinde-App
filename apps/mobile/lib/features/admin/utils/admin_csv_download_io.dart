import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String?> downloadCsv(String filename, String contents) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$filename');
  await file.writeAsString(contents);
  return file.path;
}
