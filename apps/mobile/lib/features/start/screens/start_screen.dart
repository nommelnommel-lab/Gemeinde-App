import 'package:flutter/material.dart';

import '../../../shared/auth/app_permissions.dart';
import '../../../shared/di/app_services_scope.dart';
import '../../../shared/navigation/app_router.dart';
import '../../warnings/utils/warning_formatters.dart';
import '../../posts/models/post.dart';
import '../../posts/screens/post_detail_screen.dart';
import '../../posts/services/posts_service.dart';

class StartFeedScreen extends StatefulWidget {
  const StartFeedScreen({
    super.key,
    required this.onSelectTab,
  });

  final ValueChanged<int> onSelectTab;

  @override
  State<StartFeedScreen> createState() => _StartFeedScreenState();
}

class _StartFeedScreenState extends State<StartFeedScreen> {
  late final PostsService _postsService;
  bool _initialized = false;

  bool _loading = true;
  String? _error;
  List<Post> _items = const [];
  _FeedFilter _selectedFilter = _FeedFilter.all;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final services = AppServicesScope.of(context);
    _postsService = services.postsService;
    _initialized = true;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final posts = await _postsService.getPosts();
      setState(() {
        _items = _buildFeedItems(posts);
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredItems = _filteredItems();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StartCard(
            title: 'GemeindeApp',
            subtitle: 'Angebote und Veranstaltungen entdecken',
            icon: Icons.groups,
            onTap: () => widget.onSelectTab(2),
          ),
          const SizedBox(height: 16),
          _StartCard(
            title: 'Verwaltung',
            subtitle: 'Formulare und Infos aus der Gemeinde',
            icon: Icons.admin_panel_settings,
            onTap: () => widget.onSelectTab(3),
          ),
          const SizedBox(height: 24),
          Text(
            'Nachbarschaft',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _FeedFilters(
            selected: _selectedCategory,
            onSelected: (category) {
              setState(() => _selectedCategory = category);
            },
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            _ErrorView(error: _error!, onRetry: _load)
          else if (filteredItems.isEmpty)
            const Text('Zurzeit sind keine passenden Beiträge verfügbar.')
          else
            ...filteredItems.map(
              (item) => _FeedListTile(
                item: item,
                formattedDate: _formatDate(_displayDate(item)),
                onTap: () => _handleTap(item),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return formatDate(date);
  }

  List<Post> _buildFeedItems(List<Post> posts) {
    final filtered = _activePosts(posts);
    filtered.sort((a, b) => _displayDate(b).compareTo(_displayDate(a)));
    return filtered;
  }

  List<Post> _filteredItems() {
    switch (_selectedFilter) {
      case _FeedFilter.all:
        return _items;
      case _FeedFilter.events:
        return _items
            .where((item) => item.type == PostType.event)
            .toList();
      case _FeedFilter.news:
        return _items
            .where((item) => item.type == PostType.news)
            .toList();
      case _FeedFilter.warnings:
        return _items
            .where((item) => item.type == PostType.warning)
            .toList();
    }
    return _items
        .where((item) => item.category == _selectedCategory)
        .toList();
  }

  List<Post> _activePosts(List<Post> posts) {
    final now = DateTime.now();
    return posts
        .where(
          (post) =>
              post.type != PostType.warning ||
              post.validUntil == null ||
              post.validUntil!.isAfter(now),
        )
        .toList();
  }

  void _handleTap(Post item) {
    AppRouterScope.of(context).push(
      PostDetailScreen(
        post: item,
        postsService: _postsService,
        isAdmin:
            AppPermissionsScope.maybePermissionsOf(context)?.canManageContent ??
                false,
      ),
    );
  }

  DateTime _displayDate(Post post) {
    if (post.type == PostType.event && post.date != null) {
      return post.date!;
    }
    return post.createdAt;
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                child: Icon(icon, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

enum _FeedFilter {
  all,
  events,
  news,
  warnings,
}

class _FeedFilters extends StatelessWidget {
  const _FeedFilters({
    required this.selected,
    required this.onSelected,
  });

  final PostCategory? selected;
  final ValueChanged<PostCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    final filters = <PostCategory?>[null, ...PostCategory.values];

    return Wrap(
      spacing: 8,
      children: filters.map((category) {
        final label = category == null ? 'Alle' : category.label;
        return ChoiceChip(
          label: Text(label),
          selected: category == selected,
          onSelected: (_) => onSelected(category),
        );
      }).toList(),
    );
  }
}

class _FeedListTile extends StatelessWidget {
  const _FeedListTile({
    required this.item,
    required this.formattedDate,
    required this.onTap,
  });

  final Post item;
  final String formattedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: const Icon(Icons.chat_bubble_outline),
        title: Text(item.title),
        subtitle: Text(
          '${item.category.label} · $formattedDate\n${_preview(item.body)}',
          style: theme.textTheme.bodySmall,
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  IconData _iconForType(PostType type) {
    switch (type) {
      case PostType.event:
        return Icons.event;
      case PostType.news:
        return Icons.newspaper;
      case PostType.warning:
        return Icons.warning_amber;
    }
  }

  String _labelForType(PostType type) => type.label;
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Feed konnte nicht geladen werden',
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
      ),
    );
  }
}
