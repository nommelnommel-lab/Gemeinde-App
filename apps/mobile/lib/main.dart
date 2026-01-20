import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'api/health_service.dart';
import 'config/app_config.dart';

>>>>>>> origin/codex/implement-bottom-navigation-layout-with-tabs-bk8xnj
import 'features/navigation/screens/main_navigation_screen.dart';
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

    return AppRouterScope(
      router: _router,
      child: MaterialApp(
        title: 'Gemeinde App',
        theme: AppTheme.light(),
        navigatorKey: _router.navigatorKey,

        home: MainNavigationScreen(
          healthService: healthService,
          eventsService: eventsService,
        ),
>>>>>>> origin/codex/implement-bottom-navigation-layout-with-tabs-bk8xnj
      ),
    );
  }
}
