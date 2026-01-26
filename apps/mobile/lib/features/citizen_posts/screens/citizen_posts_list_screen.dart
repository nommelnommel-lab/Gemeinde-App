import 'package:flutter/material.dart';

import '../../../shared/auth/app_permissions.dart';
import '../../../shared/auth/auth_scope.dart';
import '../../../shared/navigation/app_router.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_states.dart';
import '../../auth/screens/login_screen.dart';
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
  bool _initialized = false;
  bool _loading = true;
  String? _error;
  bool _onlyMine = false;
  List<CitizenPost> _posts = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authStore = AuthScope.of(context);
      final authorUserId = authStore.user?.id;
      final posts = await widget.postsService.getPosts(
        type: widget.type,
        onlyMine: _onlyMine,
        authorUserId: authorUserId,
      );
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
    final authStore = AuthScope.of(context);
    final canFilterMine =
        authStore.isAuthenticated && authStore.user?.id != null;

    return AppScaffold(
      appBar: AppBar(title: Text(widget.type.label)),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _openCreate,
              icon: const Icon(Icons.add),
              label: const Text('Hinzufügen'),
            )
          : null,
      padBody: false,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (canFilterMine)
              Card(
                child: SwitchListTile(
                  title: const Text('Nur meine'),
                  subtitle: const Text('Nur eigene Beiträge anzeigen.'),
                  value: _onlyMine,
                  onChanged: (value) {
                    setState(() => _onlyMine = value);
                    _load();
                  },
                ),
              ),
            if (canFilterMine) const SizedBox(height: 12),
            if (_loading)
              const LoadingState(message: 'Beiträge werden geladen...')
            else if (_error != null)
              _buildErrorState()
            else if (_posts.isEmpty)
              EmptyState(
                icon: Icons.forum_outlined,
                title: 'Keine Beiträge',
                message: _emptyMessage(),
              )
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
    );
  }

  String _emptyMessage() {
    final label = widget.type.label;
    if (_onlyMine) {
      return 'Du hast noch keine Beiträge in $label.';
    }
    return 'Noch keine Beiträge in $label.';
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
    final result = await AppRouterScope.of(context).push<bool>(
      CitizenPostDetailScreen(
        post: post,
        postsService: widget.postsService,
      ),
    );
    if (result == true) {
      _load();
    }
  }

  Future<void> _openCreate() async {
    final result = await AppRouterScope.of(context).push<CitizenPost?>(
      CitizenPostFormScreen(
        type: widget.type,
        postsService: widget.postsService,
      ),
    );
    if (result != null) {
      _load();
    }
  }

  Widget _buildErrorState() {
    final normalized = _error!.toLowerCase();
    final isAuthError = normalized.contains('http 401') ||
        normalized.contains('http 403') ||
        normalized.contains('sitzung abgelaufen');
    return ErrorState(
      message: _error!,
      onRetry: _load,
      secondaryAction: isAuthError
          ? OutlinedButton(
              onPressed: () {
                AppRouterScope.of(context).push(const LoginScreen());
              },
              child: const Text('Anmelden'),
            )
          : null,
    );
  }
}
