import 'package:flutter/material.dart';

import '../../../shared/navigation/app_router.dart';
import '../models/post.dart';
import '../services/posts_service.dart';
import 'post_detail_screen.dart';
import 'post_form_screen.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({
    super.key,
    required this.category,
    required this.postsService,
    this.isAdmin = false,
  });

  final PostCategory category;
  final PostsService postsService;
  final bool isAdmin;

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  bool _loading = true;
  String? _error;
  List<Post> _posts = const [];

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
      final posts = await widget.postsService.getPosts(widget.category);
      setState(() => _posts = posts);
    } catch (e) {
      setState(() => _error = 'Beiträge konnten nicht geladen werden.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.label)),
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
                    subtitle: Text(
                      '${_formatDate(post.createdAt)} · ${_preview(post.body)}',
                    ),
                    trailing: widget.isAdmin
                        ? const Icon(Icons.chevron_right)
                        : null,
                    onTap: () => _openDetail(post),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: _openCreate,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _openDetail(Post post) async {
    final result = await AppRouterScope.of(context).push<bool>(
      PostDetailScreen(
        post: post,
        postsService: widget.postsService,
        isAdmin: widget.isAdmin,
      ),
    );

    if (result == true) {
      _load();
    }
  }

  Future<void> _openCreate() async {
    final result = await AppRouterScope.of(context).push<bool>(
      PostFormScreen(
        postsService: widget.postsService,
        category: widget.category,
      ),
    );

    if (result == true) {
      _load();
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  String _preview(String body) {
    const maxLength = 60;
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
