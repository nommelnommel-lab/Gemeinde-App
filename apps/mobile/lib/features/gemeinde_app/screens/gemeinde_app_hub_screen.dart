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
          title: 'Beiträge & Markt',
          icon: Icons.storefront,
          onTap: () => _openCitizenList(
            context,
            title: 'Beiträge & Markt',
            types: [CitizenPostType.marketplace],
          ),
        ),
        _HubItem(
          title: 'Umzug/Entrümpelung',
          icon: Icons.local_shipping,
          onTap: () => _openCitizenList(
            context,
            title: 'Umzug/Entrümpelung',
            types: [CitizenPostType.movingClearance],
          ),
        ),
        _HubItem(
          title: 'Hilfe & Ehrenamt',
          icon: Icons.volunteer_activism,
          onTap: () => _openCitizenList(
            context,
            title: 'Hilfe & Ehrenamt',
            types: [CitizenPostType.help],
          ),
        ),
        _HubItem(
          title: 'Mobilität',
          icon: Icons.directions_car,
          onTap: () => _openCitizenList(
            context,
            title: 'Mobilität',
            types: [CitizenPostType.apartmentSearch],
          ),
        ),
        _HubItem(
          title: 'Wohnen & Alltag',
          icon: Icons.home,
          onTap: () => _openCitizenList(
            context,
            title: 'Wohnen & Alltag',
            types: [CitizenPostType.lostFound],
          ),
        ),
      ]);
    }
    final communityTypes = <CitizenPostType>[];
    if (settingsStore.isFeatureEnabled('places')) {
      items.add(
        _HubItem(
          title: 'Café Treff',
          icon: Icons.local_cafe,
          onTap: () => _openCitizenList(
            context,
            title: 'Café Treff',
            types: [CitizenPostType.cafeMeetup],
          ),
        ),
      );
    }
    if (settingsStore.isFeatureEnabled('clubs')) {
      communityTypes.add(CitizenPostType.kidsMeetup);
    }
    if (communityTypes.isNotEmpty) {
      items.add(
        _HubItem(
          title: 'Treffen & Gemeinschaft',
          icon: Icons.local_cafe,
          onTap: () => _openCitizenList(
            context,
            title: 'Treffen & Gemeinschaft',
            types: communityTypes,
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
    BuildContext context, {
    required String title,
    required List<CitizenPostType> types,
  }) {
    final services = AppServicesScope.of(context);
    AppRouterScope.of(context).push(
      CitizenPostsListScreen(
        title: title,
        types: types,
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
