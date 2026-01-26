import 'package:flutter/material.dart';

import '../../api/health_service.dart';
import '../../features/events/services/events_service.dart';
import '../../features/admin/services/admin_service.dart';
import '../../features/citizen_posts/services/citizen_posts_service.dart';
import '../../features/news/services/news_service.dart';
import '../../features/posts/services/posts_service.dart';
import '../../features/start/services/feed_service.dart';
import '../../features/tourism/services/tourism_service.dart';
import '../../features/verwaltung/services/tenant_config_service.dart';
import '../../features/verwaltung/services/verwaltung_service.dart';
import '../../features/warnings/services/warnings_service.dart';
import '../auth/permissions_service.dart';
import '../tenant/tenant_store.dart';

class AppServices {
  const AppServices({
    required this.adminService,
    required this.citizenPostsService,
    required this.eventsService,
    required this.feedService,
    required this.newsService,
    required this.postsService,
    required this.healthService,
    required this.tenantConfigService,
    required this.warningsService,
    required this.tourismService,
    required this.permissionsService,
    required this.verwaltungService,
    required this.tenantStore,
  });

  final AdminService adminService;
  final CitizenPostsService citizenPostsService;
  final EventsService eventsService;
  final FeedService feedService;
  final NewsService newsService;
  final PostsService postsService;
  final HealthService healthService;
  final TenantConfigService tenantConfigService;
  final WarningsService warningsService;
  final TourismService tourismService;
  final PermissionsService permissionsService;
  final VerwaltungService verwaltungService;
  final TenantStore tenantStore;
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
