import 'package:flutter/material.dart';

import '../../../shared/auth/auth_scope.dart';
import '../../../shared/navigation/app_router.dart';
import '../models/citizen_post.dart';
import '../services/citizen_posts_service.dart';
import 'citizen_post_form_screen.dart';

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
  bool _reported = false;
  bool _isReporting = false;
  bool _isDeleting = false;
  bool _didChange = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildMetadataItems(_post);
    final authStore = AuthScope.of(context);
    final isAuthenticated = authStore.isAuthenticated;
    final userId = authStore.user?.id;
    final isAuthor = userId != null &&
        userId.isNotEmpty &&
        userId == _post.authorUserId;
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_didChange);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_post.title),
          actions: [
            if (isAuthenticated)
              IconButton(
                onPressed:
                    _reported || _isReporting ? null : () => _report(context),
                icon: Icon(
                  _reported ? Icons.flag : Icons.flag_outlined,
                ),
                tooltip: _reported ? 'Gemeldet' : 'Melden',
              ),
            if (isAuthor)
              IconButton(
                onPressed: _openEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Bearbeiten',
              ),
            if (isAuthor)
              IconButton(
                onPressed: _isDeleting ? null : _confirmDelete,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Löschen',
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              _post.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(_post.body),
            const SizedBox(height: 16),
            Text(
              'Erstellt am ${_formatDate(_post.createdAt.toIso8601String())}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
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
      ),
    );
  }

  Future<void> _openEdit() async {
    final result = await AppRouterScope.of(context).push<CitizenPost?>(
      CitizenPostFormScreen(
        type: _post.type,
        postsService: widget.postsService,
        post: _post,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _post = result;
        _didChange = true;
      });
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Beitrag löschen'),
            content: const Text(
              'Möchtest du diesen Beitrag wirklich löschen?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Löschen'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm || _isDeleting) {
      return;
    }
    setState(() => _isDeleting = true);
    try {
      await widget.postsService.deletePost(_post.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beitrag wurde gelöscht.')),
      );
      AppRouterScope.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beitrag konnte nicht gelöscht werden.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
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
    setState(() => _isReporting = true);
    try {
      await widget.postsService.reportPost(_post.id);
      if (!context.mounted) return;
      setState(() => _reported = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gemeldet')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beitrag konnte nicht gemeldet werden.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isReporting = false);
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
