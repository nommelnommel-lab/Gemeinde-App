import 'package:flutter/material.dart';

import '../../../shared/navigation/app_router.dart';
import '../../../shared/widgets/placeholder_screen.dart';
import '../../events/screens/events_screen.dart';
import '../../events/services/events_service.dart';

class GemeindeAppHubScreen extends StatelessWidget {
  const GemeindeAppHubScreen({
    super.key,
    required this.eventsService,
  });

  final EventsService eventsService;

  @override
  Widget build(BuildContext context) {
    final items = [
      _HubItem(
        title: 'Events',
        icon: Icons.event,
        onTap: () {
          AppRouterScope.of(context).push(
            EventsScreen(eventsService: eventsService),
          );
        },
      ),
      _HubItem(
        title: 'Online Flohmarkt',
        icon: Icons.storefront,
        onTap: () => _openPlaceholder(
          context,
          title: 'Online Flohmarkt',
          description: 'Hier entsteht der digitale Flohmarkt der Gemeinde.',
        ),
      ),
      _HubItem(
        title: 'Umzug/Entrümpelung',
        icon: Icons.local_shipping,
        onTap: () => _openPlaceholder(
          context,
          title: 'Umzug/Entrümpelung',
          description: 'Hier kannst du künftig Hilfe bei Umzug und Entrümpelung finden.',
        ),
      ),
      _HubItem(
        title: 'Senioren Hilfe',
        icon: Icons.volunteer_activism,
        onTap: () => _openPlaceholder(
          context,
          title: 'Senioren Hilfe',
          description: 'Unterstützungsangebote für Seniorinnen und Senioren.',
        ),
      ),
      _HubItem(
        title: 'Café Treff',
        icon: Icons.local_cafe,
        onTap: () => _openPlaceholder(
          context,
          title: 'Café Treff',
          description: 'Hier findest du bald Treffpunkte und Termine für den Café Treff.',
        ),
      ),
      _HubItem(
        title: 'Kinderspielen (3j-5j)',
        icon: Icons.child_friendly,
        onTap: () => _openPlaceholder(
          context,
          title: 'Kinderspielen (3j-5j)',
          description: 'Spiel- und Betreuungsangebote für Kinder von 3 bis 5 Jahren.',
        ),
      ),
      _HubItem(
        title: 'News / Aktuelles in der Umgebung',
        icon: Icons.newspaper,
        onTap: () => _openPlaceholder(
          context,
          title: 'News / Aktuelles in der Umgebung',
          description: 'Aktuelle Meldungen aus der Umgebung folgen hier.',
        ),
      ),
      _HubItem(
        title: 'Warnungen',
        icon: Icons.warning_amber,
        onTap: () => _openPlaceholder(
          context,
          title: 'Warnungen',
          description: 'Warnmeldungen werden hier angezeigt.',
        ),
      ),
    ];

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

  void _openPlaceholder(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    AppRouterScope.of(context).push(
      PlaceholderScreen(title: title, description: description),
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
