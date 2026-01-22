import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'api/health_service.dart';
import 'config/app_config.dart';
import 'features/events/services/events_service.dart';
import 'features/navigation/screens/main_navigation_screen.dart';
import 'features/news/services/news_service.dart';
import 'features/warnings/services/warnings_service.dart';
import 'shared/navigation/app_router.dart';
import 'shared/theme/app_theme.dart';

void main() {
  runApp(GemeindeApp());
}

class GemeindeApp extends StatelessWidget {
  GemeindeApp({super.key});

  final AppRouter _router = AppRouter(GlobalKey<NavigatorState>());

  @override
  Widget build(BuildContext context) {
    final api = ApiClient(baseUrl: AppConfig.apiBaseUrl);
    final healthService = HealthService(api);
    final eventsService = EventsService(api);
    final warningsService = WarningsService(api);
    final newsService = NewsService();

    return AppRouterScope(
      router: _router,
      child: MaterialApp(
        title: 'Gemeinde App',
        theme: AppTheme.light(),
        navigatorKey: _router.navigatorKey,
        home: MainNavigationScreen(
          healthService: healthService,
          eventsService: eventsService,
          warningsService: warningsService,
          newsService: newsService,
        ),
      ),
    );
  }
}
