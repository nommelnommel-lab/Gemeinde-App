import 'package:flutter/material.dart';

import '../../../shared/navigation/app_router.dart';
import '../models/post.dart';
import '../services/posts_service.dart';
import 'post_form_screen.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.post,
    required this.postsService,
    this.isAdmin = false,
  });

  final Post post;
  final PostsService postsService;
  final bool isAdmin;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Post _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_post.title),
        actions: [
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _openEdit,
              tooltip: 'Bearbeiten',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _post.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(label: Text(_post.category.label)),
                Text(
                  _formatDate(_post.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _post.body,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEdit() async {
    final result = await AppRouterScope.of(context).push<bool>(
      PostFormScreen(
        postsService: widget.postsService,
        category: _post.category,
        post: _post,
      ),
    );

    if (result == true) {
      final posts = await widget.postsService.getPosts(_post.category);
      final updated = posts.firstWhere((post) => post.id == _post.id,
          orElse: () => _post);
      if (mounted) {
        setState(() => _post = updated);
      }
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }
}
