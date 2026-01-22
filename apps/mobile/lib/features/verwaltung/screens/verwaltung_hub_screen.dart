import 'package:flutter/material.dart';

import '../../../shared/navigation/app_router.dart';
import '../../../shared/widgets/coming_soon_screen.dart';
import 'tenant_info_screen.dart';

class VerwaltungHubScreen extends StatelessWidget {
  const VerwaltungHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _VerwaltungItem(
        title: 'Formulare',
        description: 'Formulare und Anträge folgen hier.',
        icon: Icons.description_outlined,
        onTap: () => _openComingSoon(
          context,
          itemTitle: 'Formulare',
          itemDescription: 'Formulare und Anträge folgen hier.',
        ),
      ),
      _VerwaltungItem(
        title: 'Rathaus Infos',
        description: 'Informationen rund um das Rathaus folgen hier.',
        icon: Icons.account_balance_outlined,
        onTap: () => _openComingSoon(
          context,
          itemTitle: 'Rathaus Infos',
          itemDescription: 'Informationen rund um das Rathaus folgen hier.',
        ),
      ),
      _VerwaltungItem(
        title: 'Öffnungszeiten & Kontakt',
        description: 'Öffnungszeiten und Kontaktdaten der Verwaltung.',
        icon: Icons.schedule,
        onTap: () => AppRouterScope.of(context).push(
          const TenantInfoScreen(),
        ),
      ),
      _VerwaltungItem(
        title: 'Ansprechpartner',
        description: 'Kontaktpersonen der Verwaltung folgen hier.',
        icon: Icons.support_agent,
        onTap: () => _openComingSoon(
          context,
          itemTitle: 'Ansprechpartner',
          itemDescription: 'Kontaktpersonen der Verwaltung folgen hier.',
        ),
      ),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _VerwaltungTile(
          item: item,
          onTap: item.onTap,
        );
      },
    );
  }

  void _openComingSoon(
    BuildContext context, {
    required String itemTitle,
    required String itemDescription,
  }) {
    AppRouterScope.of(context).push(
      ComingSoonScreen(title: itemTitle, description: itemDescription),
    );
  }
}

class _VerwaltungItem {
  const _VerwaltungItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
}

class _VerwaltungTile extends StatelessWidget {
  const _VerwaltungTile({
    required this.item,
    required this.onTap,
  });

  final _VerwaltungItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
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
