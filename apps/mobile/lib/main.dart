import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/api_client.dart';
import 'api/health_service.dart';
import 'config/app_config.dart';
import 'features/events/services/events_service.dart';
import 'features/news/services/news_service.dart';
import 'features/navigation/screens/main_navigation_screen.dart';
import 'features/warnings/services/warnings_service.dart';
import 'shared/auth/admin_key_store.dart';
import 'shared/auth/app_permissions.dart';
import 'shared/auth/permissions_service.dart';
import 'shared/di/app_services_scope.dart';
import 'shared/navigation/app_router.dart';
import 'shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final adminKeyStore = AdminKeyStore(prefs);
  runApp(GemeindeApp(adminKeyStore: adminKeyStore));
}

class GemeindeApp extends StatefulWidget {
  const GemeindeApp({super.key, required this.adminKeyStore});

  final AdminKeyStore adminKeyStore;

  @override
  State<GemeindeApp> createState() => _GemeindeAppState();
}

class _GemeindeAppState extends State<GemeindeApp> {
  late final AppRouter _router;
  late final ApiClient _apiClient;
  late final AppServices _services;
  AppPermissions _permissions = const AppPermissions(canManageContent: false);

  @override
  void initState() {
    super.initState();
    _router = AppRouter(GlobalKey<NavigatorState>());
    _apiClient = ApiClient(
      baseUrl: AppConfig.apiBaseUrl,
      adminKeyStore: widget.adminKeyStore,
    );
    _services = AppServices(
      eventsService: EventsService(_apiClient),
      newsService: NewsService(_apiClient),
      healthService: HealthService(_apiClient),
      warningsService: WarningsService(_apiClient),
      permissionsService: PermissionsService(_apiClient),
      adminKeyStore: widget.adminKeyStore,
    );
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final permissions = await _services.permissionsService.getPermissions();
    if (!mounted) return;
    setState(() => _permissions = permissions);
  }

  @override
  Widget build(BuildContext context) {
    return AppRouterScope(
      router: _router,
      child: AppServicesScope(
        services: _services,
        child: AppPermissionsScope(
          permissions: _permissions,
          child: MaterialApp(
            title: 'Gemeinde App',
            theme: AppTheme.light(),
            navigatorKey: _router.navigatorKey,
            home: const MainNavigationScreen(),
          ),
        ),
      ),
    );
  }
}
