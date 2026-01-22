import 'package:flutter/material.dart';

import '../../../shared/navigation/app_router.dart';
import '../../../shared/widgets/coming_soon_screen.dart';

class VerwaltungHubScreen extends StatelessWidget {
  const VerwaltungHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _VerwaltungItem(
        title: 'Formulare',
        description: 'Formulare und Anträge folgen hier.',
        icon: Icons.description_outlined,
      ),
      _VerwaltungItem(
        title: 'Müllkalender',
        description: 'Abholtermine und Erinnerungen werden hier angezeigt.',
        icon: Icons.delete_outline,
      ),
      _VerwaltungItem(
        title: 'Öffnungszeiten',
        description: 'Hier findest du die Öffnungszeiten der Verwaltung.',
        icon: Icons.schedule,
      ),
      _VerwaltungItem(
        title: 'Ansprechpartner',
        description: 'Kontaktpersonen der Verwaltung folgen hier.',
        icon: Icons.support_agent,
      ),
      _VerwaltungItem(
        title: 'Schäden melden',
        description: 'Melde Schäden oder Anliegen direkt an die Gemeinde.',
        icon: Icons.report_problem_outlined,
      ),
      _VerwaltungItem(
        title: 'Gebühren/Steuern',
        description: 'Übersicht zu Gebühren und Steuern kommt bald.',
        icon: Icons.receipt_long_outlined,
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
          onTap: () => _openComingSoon(context, item: item),
        );
      },
    );
  }

  void _openComingSoon(BuildContext context, {required _VerwaltungItem item}) {
    AppRouterScope.of(context).push(
      ComingSoonScreen(title: item.title, description: item.description),
    );
  }
}

class _VerwaltungItem {
  const _VerwaltungItem({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
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
