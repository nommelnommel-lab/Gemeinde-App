import 'package:flutter/material.dart';

import '../../../shared/di/app_services_scope.dart';
import '../../../shared/navigation/app_router.dart';
import '../../../shared/tenant/tenant_settings_scope.dart';
import '../../citizen_posts/models/citizen_post.dart';
import '../../citizen_posts/screens/citizen_posts_list_screen.dart';
import '../../events/screens/events_screen.dart';
import '../../news/screens/news_screen.dart';

class GemeindeAppHubScreen extends StatelessWidget {
  const GemeindeAppHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsStore = TenantSettingsScope.of(context);
    final services = AppServicesScope.of(context);
    final items = <_HubItem>[];

    if (settingsStore.isFeatureEnabled('events')) {
      items.add(
        _HubItem(
          title: 'Events',
          icon: Icons.event,
          onTap: () {
            AppRouterScope.of(context).push(
              const EventsScreen(),
            );
          },
        ),
      );
    }
    if (settingsStore.isFeatureEnabled('services')) {
      items.addAll([
        _HubItem(
          title: 'Online Flohmarkt',
          icon: Icons.storefront,
          onTap: () => _openCitizenList(
            context,
            CitizenPostType.marketplace,
            services,
          ),
        ),
        _HubItem(
          title: 'Umzug/Entrümpelung',
          icon: Icons.local_shipping,
          onTap: () => _openCitizenList(
            context,
            CitizenPostType.movingClearance,
            services,
          ),
        ),
        _HubItem(
          title: 'Senioren Hilfe',
          icon: Icons.volunteer_activism,
          onTap: () => _openCitizenList(
            context,
            CitizenPostType.help,
            services,
          ),
        ),
        _HubItem(
          title: 'Wohnungssuche',
          icon: Icons.home_work_outlined,
          onTap: () => _openCitizenList(
            context,
            CitizenPostType.apartmentSearch,
            services,
          ),
        ),
        _HubItem(
          title: 'Fundbüro',
          icon: Icons.search,
          onTap: () => _openCitizenList(
            context,
            CitizenPostType.lostFound,
            services,
          ),
        ),
      ]);
    }
    if (settingsStore.isFeatureEnabled('places')) {
      items.add(
        _HubItem(
          title: 'Café Treff',
          icon: Icons.local_cafe,
          onTap: () => _openCitizenList(
            context,
            CitizenPostType.cafeMeetup,
            services,
          ),
        ),
      );
    }
    if (settingsStore.isFeatureEnabled('clubs')) {
      items.add(
        _HubItem(
          title: 'Kinderspielen (3j-5j)',
          icon: Icons.child_friendly,
          onTap: () => _openCitizenList(
            context,
            CitizenPostType.kidsMeetup,
            services,
          ),
        ),
      );
    }
    if (settingsStore.isFeatureEnabled('posts')) {
      items.add(
        _HubItem(
          title: 'News / Aktuelles in der Umgebung',
          icon: Icons.newspaper,
          onTap: () {
            AppRouterScope.of(context).push(
              const NewsScreen(),
            );
          },
        ),
      );
    }

    if (items.isEmpty) {
      return const Center(
        child: Text('Für diese Gemeinde sind keine Module aktiviert.'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _HubTile(item: item);
      },
    );
  }

  void _openCitizenList(
    BuildContext context,
    CitizenPostType type,
    AppServices services,
  ) {
    AppRouterScope.of(context).push(
      CitizenPostsListScreen(
        type: type,
        postsService: services.citizenPostsService,
      ),
    );
  }
}

class _HubItem {
  const _HubItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
}

class _HubTile extends StatelessWidget {
  const _HubTile({required this.item});

  final _HubItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 32),
              const SizedBox(height: 12),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
