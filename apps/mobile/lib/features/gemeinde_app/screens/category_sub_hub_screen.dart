import 'package:flutter/material.dart';

import '../../../shared/auth/app_permissions.dart';
import '../../../shared/di/app_services_scope.dart';
import '../../../shared/navigation/app_router.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../../../shared/widgets/app_states.dart';
import '../../citizen_posts/models/citizen_post.dart';
import '../../citizen_posts/screens/citizen_post_detail_screen.dart';
import '../../citizen_posts/screens/citizen_post_form_screen.dart';
import '../../citizen_posts/screens/citizen_posts_list_screen.dart';

class CategorySubHubScreen extends StatefulWidget {
  const CategorySubHubScreen({
    super.key,
    required this.title,
    required this.types,
    required this.subTiles,
    this.filterTypes,
    this.createOptions,
    this.extraActions = const [],
  });

  final String title;
  final List<CitizenPostType> types;
  final List<CategorySubTile> subTiles;
  final List<CitizenPostType>? filterTypes;
  final List<CategoryCreateOption>? createOptions;
  final List<CategorySubAction> extraActions;

  @override
  State<CategorySubHubScreen> createState() => _CategorySubHubScreenState();
}

class _CategorySubHubScreenState extends State<CategorySubHubScreen> {
  static const _previewLimit = 5;
  static const _emptyHint =
      'Einträge können von der Verwaltung im Web-Admin ergänzt werden.';
  bool _initialized = false;
  bool _loading = true;
  String? _error;
  List<CitizenPost> _posts = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    if (widget.types.isEmpty) {
      setState(() {
        _posts = const [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final postsService = AppServicesScope.of(context).citizenPostsService;
      final posts = await postsService.getPostsForTypes(
        types: widget.types,
      );
      final preview = posts.take(_previewLimit).toList();
      if (mounted) {
        setState(() => _posts = preview);
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
    final isTourist = permissions?.role == 'TOURIST';
    final canCreate = !isTourist && _creatableOptions(permissions).isNotEmpty;
    return AppScaffold(
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _openCreate,
              icon: const Icon(Icons.add),
              label: const Text('Erstellen'),
            )
          : null,
      padBody: false,
      body: RefreshIndicator(
        onRefresh: _loadPreview,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const AppSectionHeader(
              title: 'Aktuell',
              subtitle: 'Neueste Beiträge aus dieser Kategorie.',
            ),
            const SizedBox(height: 12),
            if (_loading)
              const LoadingState(message: 'Beiträge werden geladen...')
            else if (_error != null)
              ErrorState(message: _error!, onRetry: _loadPreview)
            else if (_posts.isEmpty)
              const EmptyState(
                icon: Icons.forum_outlined,
                title: 'Noch keine Einträge',
                message: 'In dieser Kategorie gibt es noch keine Beiträge.',
                hint: _emptyHint,
              )
            else
              ..._posts.map(
                (post) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: () => _openDetail(post),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _previewSubtitle(post),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const AppSectionHeader(
              title: 'Bereiche',
              subtitle: 'Wähle einen Bereich, um gezielt zu filtern.',
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth < 360 ? 1 : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  children: widget.subTiles
                      .map((tile) => _SubTileCard(tile: tile))
                      .toList(),
                );
              },
            ),
            if (widget.extraActions.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...widget.extraActions.map(
                (action) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: action.onTap,
                    child: ListTile(
                      leading: Icon(action.icon),
                      title: Text(action.label),
                      subtitle:
                          action.subtitle != null ? Text(action.subtitle!) : null,
                    ),
                  ),
                ),
              ),
            ],
            if (widget.types.isNotEmpty) ...[
              const SizedBox(height: 4),
              AppCard(
                onTap: _openAll,
                child: const ListTile(
                  leading: Icon(Icons.view_list),
                  title: Text('Alle anzeigen'),
                  subtitle: Text('Gesamte Übersicht dieser Kategorie öffnen.'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _previewSubtitle(CitizenPost post) {
    final preview = post.body.trim();
    final trimmed = preview.length > 80
        ? '${preview.substring(0, 80)}…'
        : preview;
    return '${_formatDate(post.createdAt)} · ${post.type.label}\n$trimmed';
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hours = value.hour.toString().padLeft(2, '0');
    final minutes = value.minute.toString().padLeft(2, '0');
    if (value.hour == 0 && value.minute == 0) {
      return '$day.$month.$year';
    }
    return '$day.$month.$year · $hours:$minutes';
  }

  Future<void> _openDetail(CitizenPost post) async {
    final postsService = AppServicesScope.of(context).citizenPostsService;
    final result = await AppRouterScope.of(context).push<bool>(
      CitizenPostDetailScreen(
        post: post,
        postsService: postsService,
      ),
    );
    if (result == true) {
      _loadPreview();
    }
  }

  void _openAll() {
    final postsService = AppServicesScope.of(context).citizenPostsService;
    AppRouterScope.of(context).push(
      CitizenPostsListScreen(
        title: widget.title,
        types: widget.types,
        postsService: postsService,
        filterTypes: widget.filterTypes ?? widget.types,
      ),
    );
  }

  List<CategoryCreateOption> _creatableOptions(AppPermissions? permissions) {
    final create = permissions?.canCreate;
    if (create == null) {
      return const [];
    }
    final options = widget.createOptions ??
        widget.subTiles
            .map((tile) => CategoryCreateOption(tile.title, tile.type))
            .toList();
    return options
        .where((option) => _canCreateType(option.type, create))
        .toList();
  }

  Future<void> _openCreate() async {
    final permissions = AppPermissionsScope.maybePermissionsOf(context);
    if (permissions == null || permissions.role == 'TOURIST') {
      return;
    }
    final options = _creatableOptions(permissions);
    if (options.isEmpty) {
      return;
    }
    final postsService = AppServicesScope.of(context).citizenPostsService;
    CategoryCreateOption? selected;
    if (options.length == 1) {
      selected = options.first;
    } else {
      selected = await _selectCreateOption(options);
    }
    if (selected == null) {
      return;
    }
    final result = await AppRouterScope.of(context).push<CitizenPost?>(
      CitizenPostFormScreen(
        type: selected.type,
        postsService: postsService,
      ),
    );
    if (result != null) {
      _loadPreview();
    }
  }

  Future<CategoryCreateOption?> _selectCreateOption(
    List<CategoryCreateOption> options,
  ) {
    return showModalBottomSheet<CategoryCreateOption>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('Was möchtest du erstellen?'),
            ),
            ...options.map(
              (option) => ListTile(
                title: Text(option.label),
                onTap: () => Navigator.of(context).pop(option),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canCreateType(CitizenPostType type, CreatePermissions create) {
    switch (type) {
      case CitizenPostType.userPost:
        return false;
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
}

class CategorySubTile {
  const CategorySubTile({
    required this.title,
    required this.icon,
    required this.type,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final CitizenPostType type;
  final VoidCallback onTap;
}

class CategoryCreateOption {
  const CategoryCreateOption(this.label, this.type);

  final String label;
  final CitizenPostType type;
}

class CategorySubAction {
  const CategorySubAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

class _SubTileCard extends StatelessWidget {
  const _SubTileCard({required this.tile});

  final CategorySubTile tile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: tile.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(tile.icon, size: 30),
              const SizedBox(height: 12),
              Text(
                tile.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
