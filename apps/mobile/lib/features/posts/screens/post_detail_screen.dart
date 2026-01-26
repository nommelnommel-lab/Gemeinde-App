import 'package:flutter/material.dart';

import '../../../shared/navigation/app_router.dart';
import '../../warnings/utils/warning_formatters.dart';
import '../models/post.dart';
import '../services/posts_service.dart';
import 'post_form_screen.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.post,
    this.postsService,
    this.canEdit = false,
  });

  final Post post;
  final PostsService? postsService;
  final bool canEdit;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Post _post;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _load();
  }

  Future<void> _load() async {
    final postsService = widget.postsService;
    if (postsService == null) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final refreshed = await postsService.getPost(_post.id);
      if (mounted) {
        setState(() => _post = refreshed);
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
          if (widget.canEdit && widget.postsService != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _openEdit,
              tooltip: 'Bearbeiten',
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
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(label: Text(_post.type.label)),
            Text(
              _formatDate(_displayDate(_post)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_post.type == PostType.warning && _post.severity != null)
              Chip(label: Text(_post.severity!)),
          ],
        ),
        const SizedBox(height: 16),
        if (_post.type == PostType.event && _post.date != null)
          _InfoRow(
            label: 'Termin',
            value: formatDateTime(_post.date!),
          ),
        if (_post.location != null && _post.location!.trim().isNotEmpty)
          _InfoRow(
            label: 'Ort',
            value: _post.location!,
          ),
        if (_post.validUntil != null)
          _InfoRow(
            label: 'Gültig bis',
            value: formatDateTime(_post.validUntil!),
          ),
        _InfoRow(
          label: 'Erstellt',
          value: formatDateTime(_post.createdAt),
        ),
        const SizedBox(height: 16),
        Text(
          _post.body,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Future<void> _openEdit() async {
    final postsService = widget.postsService;
    if (postsService == null) {
      return;
    }
    final result = await AppRouterScope.of(context).push<bool>(
      PostFormScreen(
        postsService: postsService,
        type: _post.type,
        post: _post,
        canEdit: widget.canEdit,
      ),
    );

    if (result == true) {
      await _load();
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  DateTime _displayDate(Post post) {
    if (post.type == PostType.event && post.date != null) {
      return post.date!;
    }
    return post.createdAt;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
