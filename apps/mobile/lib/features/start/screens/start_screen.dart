import 'package:flutter/material.dart';

import '../../../shared/auth/app_permissions.dart';
import '../../../shared/navigation/app_router.dart';
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
  PostCategory? _selectedCategory;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _postsService = PostsService();
    _initialized = true;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final categories = PostCategory.values;
      final results = await Future.wait(
        categories.map(_postsService.getPosts),
      );
      final items = <Post>[];
      for (final posts in results) {
        items.addAll(posts);
      }
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() => _items = items);
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
                formattedDate: _formatDate(item.createdAt),
                onTap: () => _handleTap(item),
              ),
            ),
        ],
      ),
    );
  }

  List<Post> _filteredItems() {
    if (_selectedCategory == null) {
      return _items;
    }
    return _items
        .where((item) => item.category == _selectedCategory)
        .toList();
  }

  void _handleTap(Post item) {
    final canEdit =
        AppPermissionsScope.maybePermissionsOf(context)?.canManageContent ??
            false;
    AppRouterScope.of(context).push(
      PostDetailScreen(
        post: item,
        postsService: _postsService,
        isAdmin: canEdit,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
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

  String _preview(String body) {
    const maxLength = 70;
    final cleaned = body.trim();
    if (cleaned.length <= maxLength) {
      return cleaned;
    }
    return '${cleaned.substring(0, maxLength)}…';
  }
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
