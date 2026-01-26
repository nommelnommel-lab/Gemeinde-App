import 'package:flutter/material.dart';

import '../models/citizen_post.dart';
import '../services/citizen_posts_service.dart';

class CitizenPostDetailScreen extends StatefulWidget {
  const CitizenPostDetailScreen({
    super.key,
    required this.post,
    required this.postsService,
  });

  final CitizenPost post;
  final CitizenPostsService postsService;

  @override
  State<CitizenPostDetailScreen> createState() =>
      _CitizenPostDetailScreenState();
}

class _CitizenPostDetailScreenState extends State<CitizenPostDetailScreen> {
  late CitizenPost _post;
  bool _loading = false;
  String? _error;
  bool _reporting = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final post = await widget.postsService.getPost(_post.id);
      if (mounted) {
        setState(() => _post = post);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Beitrag konnte nicht geladen werden.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_post.title),
        actions: [
          IconButton(
            onPressed: _reporting ? null : () => _report(context),
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Melden',
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = _buildMetadataItems(_post);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_error != null) ...[
          _ErrorView(error: _error!, onRetry: _load),
          const SizedBox(height: 16),
        ],
        Text(
          _post.title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(_post.body),
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
    setState(() => _reporting = true);
    try {
      await widget.postsService.reportPost(_post.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beitrag wurde gemeldet.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Melden fehlgeschlagen: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _reporting = false);
      }
    }
  }
}

class _MetadataEntry {
  const _MetadataEntry({required this.label, required this.value});

  final String label;
  final String value;
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Etwas ist schiefgelaufen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }
}
