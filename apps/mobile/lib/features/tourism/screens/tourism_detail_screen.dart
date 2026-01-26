import 'package:flutter/material.dart';

import '../../../shared/navigation/app_router.dart';
import '../../../shared/utils/external_links.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../models/tourism_item.dart';

class TourismDetailScreen extends StatelessWidget {
  const TourismDetailScreen({
    super.key,
    required this.item,
  });

  final TourismItem item;

  @override
  Widget build(BuildContext context) {
    final address = item.metadataString('address');
    final openingHours = item.metadataString('openingHours');
    final phone = item.metadataString('phone');
    final websiteUrl = item.metadataString('websiteUrl');
    final externalLink = item.metadataString('externalLink');

    return AppScaffold(
      appBar: AppBar(
        title: Text(item.title.isEmpty ? item.type.label : item.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRouterScope.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            item.title.isEmpty ? 'Unbenannter Eintrag' : item.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            item.body.trim().isEmpty
                ? 'Keine Beschreibung verfügbar.'
                : item.body.trim(),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (address != null) ...[
            const SizedBox(height: 20),
            _DetailRow(icon: Icons.place_outlined, label: 'Adresse', value: address),
          ],
          if (openingHours != null) ...[
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.schedule,
              label: 'Öffnungszeiten',
              value: openingHours,
            ),
          ],
          if (phone != null) ...[
            const SizedBox(height: 12),
            _DetailRow(icon: Icons.phone_outlined, label: 'Telefon', value: phone),
          ],
          if (websiteUrl != null) ...[
            const SizedBox(height: 12),
            _LinkRow(
              label: 'Website',
              value: websiteUrl,
              onTap: () => openExternalLink(context, websiteUrl),
            ),
          ],
          if (externalLink != null) ...[
            const SizedBox(height: 12),
            _LinkRow(
              label: 'Mehr Infos',
              value: externalLink,
              onTap: () => openExternalLink(context, externalLink),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.link, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
