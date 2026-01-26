import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

import 'demo_config.dart';

class AppConfig {
  static const bool demoMode = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: false,
  );

  static const String tenantId = 'default';
  static const String tenantHeaderValue = 'hilders';
  static const String _siteKeyProd = String.fromEnvironment(
    'SITE_KEY',
    defaultValue: 'HD-2026-9f3c1a2b-KEY',
  );

  static String get siteKey =>
      demoMode ? DemoConfig.siteKey : _siteKeyProd;

  static String get defaultTenantId =>
      demoMode ? DemoConfig.tenantId : 'demo';

  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    if (Platform.isAndroid && kDebugMode) {
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
