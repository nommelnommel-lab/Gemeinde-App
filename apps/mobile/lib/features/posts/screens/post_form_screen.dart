import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/posts_service.dart';

class PostFormScreen extends StatefulWidget {
  const PostFormScreen({
    super.key,
    required this.postsService,
    required this.type,
    this.post,
    this.canEdit = false,
  });

  final PostsService postsService;
  final PostType type;
  final Post? post;
  final bool canEdit;

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post?.title ?? '');
    _bodyController = TextEditingController(text: widget.post?.body ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.post != null;
    final saveLabel = isEdit ? 'Aktualisieren' : 'Erstellen';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Beitrag bearbeiten' : 'Neuer Beitrag'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.type.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titel'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Inhalt'),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(saveLabel),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      _showSnackBar('Titel und Inhalt sind erforderlich.');
      return;
    }

    setState(() => _saving = true);
    try {
      final input = PostInput(
        type: widget.type,
        title: title,
        body: body,
      );
      if (widget.post == null) {
        await widget.postsService.createPost(input, canEdit: widget.canEdit);
      } else {
        await widget.postsService.updatePost(
          widget.post!.id,
          input,
          canEdit: widget.canEdit,
        );
      }
      if (!mounted) return;
      _showSnackBar('Beitrag gespeichert.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Fehler beim Speichern: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
