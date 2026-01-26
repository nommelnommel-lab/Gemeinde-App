import 'package:flutter/material.dart';

import '../../../shared/auth/app_permissions.dart';
import '../../../shared/navigation/app_router.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../models/news_item.dart';
import '../services/news_service.dart';

class NewsFormScreen extends StatefulWidget {
  const NewsFormScreen({
    super.key,
    required this.newsService,
    this.initialItem,
  });

  final NewsService newsService;
  final NewsItem? initialItem;

  @override
  State<NewsFormScreen> createState() => _NewsFormScreenState();
}

class _NewsFormScreenState extends State<NewsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late String _selectedCategory;
  bool _saving = false;

  bool get _isEditing => widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.initialItem?.title ?? '');
    _bodyController =
        TextEditingController(text: widget.initialItem?.body ?? '');
    final categories = widget.newsService.availableCategories;
    _selectedCategory = widget.initialItem?.category ?? categories.first;
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = categories.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);

    try {
      final item = _isEditing
          ? await widget.newsService.updateNews(
              id: widget.initialItem!.id,
              title: _titleController.text,
              category: _selectedCategory,
              body: _bodyController.text,
            )
          : await widget.newsService.createNews(
              title: _titleController.text,
              category: _selectedCategory,
              body: _bodyController.text,
            );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'News aktualisiert.' : 'News erstellt.',
          ),
        ),
      );
      Navigator.of(context).pop(item);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speichern fehlgeschlagen: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions =
        AppPermissionsScope.maybePermissionsOf(context) ?? AppPermissions.empty;
    final canEdit = permissions.role != 'TOURIST' &&
        permissions.canCreate.officialNews;
    if (!canEdit) {
      return AppScaffold(
        appBar: AppBar(title: const Text('News')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 36),
                const SizedBox(height: 12),
                Text(
                  'Sie haben keinen Zugriff auf das Erstellen oder Bearbeiten von News.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => AppRouterScope.of(context).pop(),
                  child: const Text('Zurück'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final categories = widget.newsService.availableCategories;

    return AppScaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'News bearbeiten' : 'News erstellen'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Speichert...' : 'Speichern'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titel',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte einen Titel angeben.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategorie',
                border: OutlineInputBorder(),
              ),
              items: categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Inhalt',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              maxLines: 8,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte Inhalt hinzufügen.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
