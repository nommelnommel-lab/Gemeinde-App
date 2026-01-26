import 'package:flutter/material.dart';

import '../../../shared/navigation/app_router.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../../events/screens/events_screen.dart';
import '../../news/screens/news_screen.dart';
import '../../warnings/screens/warnings_screen.dart';
import '../models/tourism_item.dart';
import 'tourism_list_screen.dart';

class TourismHubScreen extends StatelessWidget {
  const TourismHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const AppSectionHeader(
          title: 'Tourismus',
          subtitle: 'Entdecken Sie Angebote, Ausflugsziele und Tipps vor Ort.',
        ),
        const SizedBox(height: 12),
        _HubCard(
          title: 'Events',
          subtitle: 'Offizielle Veranstaltungen der Gemeinde',
          icon: Icons.event_available_outlined,
          onTap: () => _open(context, const EventsScreen()),
        ),
        const SizedBox(height: 12),
        _HubCard(
          title: 'News',
          subtitle: 'Aktuelle Neuigkeiten und Hinweise',
          icon: Icons.article_outlined,
          onTap: () => _open(context, const NewsScreen()),
        ),
        const SizedBox(height: 12),
        _HubCard(
          title: 'Warnungen',
          subtitle: 'Wichtige Hinweise und Sicherheitsmeldungen',
          icon: Icons.warning_amber_outlined,
          onTap: () => _open(context, const WarningsScreen()),
        ),
        const SizedBox(height: 24),
        const AppSectionHeader(
          title: 'Erlebnisse & Angebote',
          subtitle: 'Touristische Empfehlungen der Gemeinde.',
        ),
        const SizedBox(height: 12),
        _HubCard(
          title: 'Wanderrouten',
          subtitle: 'Routen, Rundwege und Naturpfade',
          icon: Icons.hiking_outlined,
          onTap: () => _open(
            context,
            const TourismListScreen(type: TourismItemType.hikingRoute),
          ),
        ),
        const SizedBox(height: 12),
        _HubCard(
          title: 'Sehenswürdigkeiten',
          subtitle: 'Beliebte Ziele und Aussichtspunkte',
          icon: Icons.location_city_outlined,
          onTap: () => _open(
            context,
            const TourismListScreen(type: TourismItemType.sight),
          ),
        ),
        const SizedBox(height: 12),
        _HubCard(
          title: 'Freizeitangebote',
          subtitle: 'Aktivitäten für Groß und Klein',
          icon: Icons.park_outlined,
          onTap: () => _open(
            context,
            const TourismListScreen(type: TourismItemType.leisure),
          ),
        ),
        const SizedBox(height: 12),
        _HubCard(
          title: 'Restaurants',
          subtitle: 'Essen gehen und genießen',
          icon: Icons.restaurant_outlined,
          onTap: () => _open(
            context,
            const TourismListScreen(type: TourismItemType.restaurant),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _open(BuildContext context, Widget screen) {
    AppRouterScope.of(context).push(screen);
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
