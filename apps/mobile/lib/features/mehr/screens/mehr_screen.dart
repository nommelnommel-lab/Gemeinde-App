import 'package:flutter/material.dart';

import '../../../api/health_service.dart';
import '../../../shared/navigation/app_router.dart';
import '../../../shared/widgets/placeholder_screen.dart';
import '../../hilfe/screens/hilfe_screen.dart';
import '../../info/screens/info_screen.dart';
import '../../systemstatus/screens/health_screen.dart';

class MehrScreen extends StatelessWidget {
  const MehrScreen({super.key, required this.healthService});

  final HealthService healthService;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.monitor_heart),
          title: const Text('Systemstatus'),
          subtitle: const Text('Backend-Status prüfen'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            AppRouterScope.of(context).push(
              HealthScreen(healthService: healthService),
            );
          },
        ),
        const Divider(height: 0),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Info'),
          subtitle: const Text('Wichtige Hinweise zur Gemeinde'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            AppRouterScope.of(context).push(const InfoScreen());
          },
        ),
        const Divider(height: 0),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Hilfe'),
          subtitle: const Text('FAQs und Kontaktmöglichkeiten'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            AppRouterScope.of(context).push(const HilfeScreen());
          },
        ),
        const Divider(height: 0),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('Einstellungen'),
          subtitle: const Text('App-Einstellungen verwalten'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            AppRouterScope.of(context).push(
              const PlaceholderScreen(
                title: 'Einstellungen',
                description:
                    'Hier können zukünftig Benachrichtigungen und weitere Optionen verwaltet werden.',
              ),
            );
          },
        ),
        const Divider(height: 0),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Datenschutz'),
          subtitle: const Text('Datenschutzinformationen'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            AppRouterScope.of(context).push(
              const PlaceholderScreen(
                title: 'Datenschutz',
                description:
                    'Datenschutzinformationen werden hier bereitgestellt.',
              ),
            );
          },
        ),
        const Divider(height: 0),
        ListTile(
          leading: const Icon(Icons.article_outlined),
          title: const Text('Impressum'),
          subtitle: const Text('Rechtliche Angaben'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            AppRouterScope.of(context).push(
              const PlaceholderScreen(
                title: 'Impressum',
                description: 'Rechtliche Angaben werden hier ergänzt.',
              ),
            );
          },
        ),
        const Divider(height: 0),
      ],
    );
  }
}
