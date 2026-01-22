import 'package:flutter/material.dart';

import '../../api/health_service.dart';
import '../../features/events/services/events_service.dart';
import '../../features/news/services/news_service.dart';
import '../../features/posts/services/posts_service.dart';
import '../../features/tenant/services/tenant_service.dart';
import '../../features/warnings/services/warnings_service.dart';
import '../auth/admin_key_store.dart';
import '../auth/permissions_service.dart';

class AppServices {
  const AppServices({
    required this.eventsService,
    required this.newsService,
    required this.postsService,
    required this.healthService,
    required this.warningsService,
    required this.permissionsService,
    required this.adminKeyStore,
    required this.tenantService,
  });

  final EventsService eventsService;
  final NewsService newsService;
  final PostsService postsService;
  final HealthService healthService;
  final WarningsService warningsService;
  final PermissionsService permissionsService;
  final AdminKeyStore adminKeyStore;
  final TenantService tenantService;
}

class AppServicesScope extends InheritedWidget {
  const AppServicesScope({
    super.key,
    required this.services,
    required super.child,
  });

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppServicesScope>();
    assert(scope != null, 'AppServicesScope not found in widget tree.');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppServicesScope oldWidget) {
    return services != oldWidget.services;
  }
}
