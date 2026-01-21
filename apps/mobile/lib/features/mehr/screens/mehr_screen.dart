import 'package:flutter/material.dart';

import '../../../api/health_service.dart';
import '../../../shared/navigation/app_router.dart';
import '../../../shared/widgets/placeholder_screen.dart';
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
          leading: const Icon(Icons.info_outline),
          title: const Text('Über die App'),
          subtitle: const Text('Version & rechtliche Hinweise'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            AppRouterScope.of(context).push(
              const PlaceholderScreen(
                title: 'Über die App',
                description:
                    'Hier findest du künftig Informationen zur App-Version und rechtlichen Hinweisen.',
              ),
            );
          },
        ),
        const Divider(height: 0),
      ],
    );
  }
}
