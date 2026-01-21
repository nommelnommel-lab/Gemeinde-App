import 'package:flutter/material.dart';

import '../../../shared/navigation/app_router.dart';
import '../../../shared/widgets/placeholder_screen.dart';

class VerwaltungHubScreen extends StatelessWidget {
  const VerwaltungHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _VerwaltungTile(
          title: 'Formulare',
          subtitle: 'Anträge und Dokumente',
          icon: Icons.description_outlined,
          onTap: () => _openPlaceholder(
            context,
            title: 'Formulare',
            description: 'Formulare und Anträge folgen hier.',
          ),
        ),
        const SizedBox(height: 12),
        _VerwaltungTile(
          title: 'Infos aus der Gemeinde',
          subtitle: 'Amtliche Mitteilungen',
          icon: Icons.account_balance,
          onTap: () => _openPlaceholder(
            context,
            title: 'Infos aus der Gemeinde',
            description: 'Amtliche Informationen werden hier veröffentlicht.',
          ),
        ),
      ],
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

class _VerwaltungTile extends StatelessWidget {
  const _VerwaltungTile({
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
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
