import 'package:flutter/material.dart';

import '../../../shared/navigation/app_router.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../../../shared/widgets/coming_soon_screen.dart';
import '../models/verwaltung_item.dart';
import 'tenant_info_screen.dart';
import 'verwaltung_items_screen.dart';

class VerwaltungHubScreen extends StatelessWidget {
  const VerwaltungHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _VerwaltungItem(
        title: 'Formulare',
        description: 'Formulare und Anträge der Gemeinde.',
        icon: Icons.description_outlined,
        onTap: () => AppRouterScope.of(context).push(
          const VerwaltungItemsScreen(kind: VerwaltungItemKind.form),
        ),
      ),
      _VerwaltungItem(
        title: 'Wichtige Links',
        description: 'Schneller Zugriff auf wichtige Services.',
        icon: Icons.link_outlined,
        onTap: () => AppRouterScope.of(context).push(
          const VerwaltungItemsScreen(kind: VerwaltungItemKind.link),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 360 ? 1 : 2;
        return CustomScrollView(
          slivers: [
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: AppSectionHeader(
                  title: 'Formulare & Verwaltung',
                  subtitle: 'Schneller Zugriff auf Services der Gemeinde.',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    return _VerwaltungTile(
                      item: item,
                      onTap: item.onTap,
                    );
                  },
                  childCount: items.length,
                ),
              ),
            ),
          ],
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
    return AppCard(
      onTap: onTap,
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
