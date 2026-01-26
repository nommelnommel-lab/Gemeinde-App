import 'package:flutter/material.dart';

import '../models/citizen_post.dart';
import '../services/citizen_posts_service.dart';

class CitizenPostDetailScreen extends StatelessWidget {
  const CitizenPostDetailScreen({
    super.key,
    required this.post,
    required this.postsService,
  });

  final CitizenPost post;
  final CitizenPostsService postsService;

  @override
  Widget build(BuildContext context) {
    final items = _buildMetadataItems(post);
    return Scaffold(
      appBar: AppBar(
        title: Text(post.title),
        actions: [
          IconButton(
            onPressed: () => _report(context),
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Melden',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            post.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(post.body),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...items.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.label),
                subtitle: Text(entry.value),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<_MetadataEntry> _buildMetadataItems(CitizenPost post) {
    final metadata = post.metadata;
    final items = <_MetadataEntry>[];

    void add(String label, dynamic value) {
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isEmpty) return;
      items.add(_MetadataEntry(label: label, value: text));
    }

    switch (post.type) {
      case CitizenPostType.marketplace:
        add('Preis', metadata['price']);
        add('Ort', metadata['location']);
        add('Kontakt', metadata['contact']);
        final images = metadata['images'];
        if (images is List) {
          add('Bilder', images.join(', '));
        }
        break;
      case CitizenPostType.movingClearance:
        add('Termin', _formatDate(metadata['dateTime'] ?? metadata['date']));
        add('Ort', metadata['location']);
        add('Kontakt', metadata['contact']);
        break;
      case CitizenPostType.help:
        add('Hilfeart', metadata['helpType']);
        add('Zeitraum', metadata['timeRange']);
        add('Kontakt', metadata['contact']);
        break;
      case CitizenPostType.cafeMeetup:
        add('Termin', _formatDate(metadata['dateTime']));
        add('Ort', metadata['location']);
        break;
      case CitizenPostType.kidsMeetup:
        add('Alter', metadata['ageRange']);
        add('Termin', _formatDate(metadata['dateTime']));
        add('Ort', metadata['location']);
        break;
      case CitizenPostType.apartmentSearch:
        add('Typ', metadata['type']);
        add('Zimmer', metadata['rooms']);
        add('Preis', metadata['price']);
        add('Kontakt', metadata['contact']);
        break;
      case CitizenPostType.lostFound:
        add('Typ', metadata['type']);
        add('Datum', _formatDate(metadata['date']));
        add('Ort', metadata['location']);
        add('Bild', metadata['image']);
        break;
      case CitizenPostType.rideSharing:
        add('Details', metadata['details']);
        break;
      case CitizenPostType.jobsLocal:
        add('Details', metadata['details']);
        break;
      case CitizenPostType.volunteering:
        add('Details', metadata['details']);
        break;
      case CitizenPostType.giveaway:
        add('Details', metadata['details']);
        break;
      case CitizenPostType.skillExchange:
        add('Details', metadata['details']);
        break;
    }

    return items;
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return '';
    }
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) {
      return value.toString();
    }
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    final hours = parsed.hour.toString().padLeft(2, '0');
    final minutes = parsed.minute.toString().padLeft(2, '0');
    if (parsed.hour == 0 && parsed.minute == 0) {
      return '$day.$month.$year';
    }
    return '$day.$month.$year · $hours:$minutes';
  }

  Future<void> _report(BuildContext context) async {
    await postsService.reportPost(post.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Beitrag wurde gemeldet.')),
    );
  }
}

class _MetadataEntry {
  const _MetadataEntry({required this.label, required this.value});

  final String label;
  final String value;
}
