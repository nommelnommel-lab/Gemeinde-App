import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'api/api_client.dart';
import 'api/health_service.dart';
import 'screens/health_screen.dart';

void main() {
  runApp(const GemeindeApp());
}

class GemeindeApp extends StatelessWidget {
  const GemeindeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiClient(baseUrl: AppConfig.apiBaseUrl);
    final healthService = HealthService(api);

    return MaterialApp(
      title: 'Gemeinde App',
      theme: ThemeData(useMaterial3: true),
      home: HealthScreen(healthService: healthService),
    );
  }
}
