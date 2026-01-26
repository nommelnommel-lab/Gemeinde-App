import 'package:flutter/material.dart';

import '../../../shared/auth/app_permissions.dart';
import '../../../shared/navigation/app_router.dart';
import '../models/citizen_post.dart';
import '../services/citizen_posts_service.dart';
import 'citizen_post_detail_screen.dart';
import 'citizen_post_form_screen.dart';

class CitizenPostsListScreen extends StatefulWidget {
  const CitizenPostsListScreen({
    super.key,
    required this.type,
    required this.postsService,
  });

  final CitizenPostType type;
  final CitizenPostsService postsService;

  @override
  State<CitizenPostsListScreen> createState() => _CitizenPostsListScreenState();
}

class _CitizenPostsListScreenState extends State<CitizenPostsListScreen> {
  bool _loading = true;
  String? _error;
  List<CitizenPost> _posts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final posts = await widget.postsService.getPosts(type: widget.type);
      if (mounted) {
        setState(() => _posts = posts);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Beiträge konnten nicht geladen werden.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = AppPermissionsScope.maybePermissionsOf(context);
    final canCreate = _canCreate(permissions);

    return Scaffold(
      appBar: AppBar(title: Text(widget.type.label)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              _ErrorView(error: _error!, onRetry: _load)
            else if (_posts.isEmpty)
              const Text('Noch keine Beiträge vorhanden.')
            else
              ..._posts.map(
                (post) => Card(
                  child: ListTile(
                    title: Text(post.title),
                    subtitle: Text(_subtitle(post)),
                    onTap: () => _openDetail(post),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: _openCreate,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  String _subtitle(CitizenPost post) {
    final metadata = post.metadata;
    final details = <String>[];

    final dateValue = metadata['dateTime'] ?? metadata['date'];
    if (dateValue is String && dateValue.isNotEmpty) {
      details.add(_formatDate(dateValue));
    }
    final location = metadata['location']?.toString().trim();
    if (location != null && location.isNotEmpty) {
      details.add(location);
    }
    final preview = post.body.trim();
    final trimmed = preview.length > 60
        ? '${preview.substring(0, 60)}…'
        : preview;
    if (details.isNotEmpty) {
      return '${details.join(' · ')}\n$trimmed';
    }
    return trimmed;
  }

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
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

  bool _canCreate(AppPermissions? permissions) {
    final create = permissions?.canCreate;
    if (create == null) {
      return false;
    }
    switch (widget.type) {
      case CitizenPostType.marketplace:
        return create.marketplace;
      case CitizenPostType.movingClearance:
        return create.movingClearance;
      case CitizenPostType.help:
        return create.help;
      case CitizenPostType.cafeMeetup:
        return create.cafeMeetup;
      case CitizenPostType.kidsMeetup:
        return create.kidsMeetup;
      case CitizenPostType.apartmentSearch:
        return create.apartmentSearch;
      case CitizenPostType.lostFound:
        return create.lostFound;
      case CitizenPostType.rideSharing:
        return create.rideSharing;
      case CitizenPostType.jobsLocal:
        return create.jobsLocal;
      case CitizenPostType.volunteering:
        return create.volunteering;
      case CitizenPostType.giveaway:
        return create.giveaway;
      case CitizenPostType.skillExchange:
        return create.skillExchange;
    }
  }

  Future<void> _openDetail(CitizenPost post) async {
    await AppRouterScope.of(context).push(
      CitizenPostDetailScreen(
        post: post,
        postsService: widget.postsService,
      ),
    );
  }

  Future<void> _openCreate() async {
    final result = await AppRouterScope.of(context).push<bool>(
      CitizenPostFormScreen(
        type: widget.type,
        postsService: widget.postsService,
      ),
    );
    if (result == true) {
      _load();
    }
  }
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
