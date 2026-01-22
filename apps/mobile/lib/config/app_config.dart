import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  static const String tenantId = 'default';
  static const String tenantHeaderValue = 'hilders';
  static const String siteKey = String.fromEnvironment(
    'SITE_KEY',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    if (Platform.isIOS) {
      return 'http://localhost:3000';
    }
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return 'http://localhost:3000';
    }
    return 'http://localhost:3000';
  }
}
