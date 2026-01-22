import 'package:flutter/material.dart';

import '../models/news_item.dart';
import '../services/news_service.dart';
import 'news_form_screen.dart';

class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({
    super.key,
    required this.item,
    required this.newsService,
  });

  final NewsItem item;
  final NewsService newsService;

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late NewsItem _item;
  bool _shouldReload = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.newsService.isAdmin;

    return WillPopScope(
      onWillPop: () async {
        if (_shouldReload) {
          Navigator.of(context).pop(true);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_item.title),
          actions: isAdmin
              ? [
                  IconButton(
                    tooltip: 'Bearbeiten',
                    icon: const Icon(Icons.edit),
                    onPressed: _openEdit,
                  ),
                  IconButton(
                    tooltip: 'Löschen',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _confirmDelete,
                  ),
                ]
              : null,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _item.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(label: Text(_item.category)),
                  Text(
                    _formatDate(_item.publishedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (_item.imageUrl != null &&
                  _item.imageUrl!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _item.imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return const SizedBox(
                        height: 180,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                _item.body,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEdit() async {
    final updatedItem = await Navigator.of(context).push<NewsItem>(
      MaterialPageRoute(
        builder: (context) => NewsFormScreen(
          newsService: widget.newsService,
          initialItem: _item,
        ),
      ),
    );

    if (updatedItem != null && mounted) {
      setState(() {
        _item = updatedItem;
        _shouldReload = true;
      });
    }
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('News löschen?'),
        content: const Text(
          'Möchtest du diese News wirklich löschen? Dieser Schritt kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await widget.newsService.deleteNews(_item.id);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Löschen fehlgeschlagen: $error')),
      );
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }
}
