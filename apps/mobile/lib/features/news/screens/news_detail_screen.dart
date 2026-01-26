import 'package:flutter/material.dart';

import '../../../shared/navigation/app_router.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../models/news_item.dart';
import '../services/news_service.dart';
import 'news_form_screen.dart';

class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({
    super.key,
    required this.item,
    required this.newsService,
    required this.canEdit,
  });

  final NewsItem item;
  final NewsService newsService;
  final bool canEdit;

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late NewsItem _item;
  bool _deleting = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleWillPop,
      child: AppScaffold(
        appBar: AppBar(
          title: Text(_item.title),
          actions: widget.canEdit
              ? [
                  IconButton(
                    tooltip: 'Bearbeiten',
                    icon: const Icon(Icons.edit),
                    onPressed: _deleting ? null : _editNews,
                  ),
                  IconButton(
                    tooltip: 'Löschen',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _deleting ? null : _confirmDelete,
                  ),
                ]
              : null,
        ),
        padBody: false,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionHeader(
                title: _item.title,
                subtitle: _formatDate(_item.publishedAt),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  AppChip(label: _item.category, icon: Icons.local_offer),
                  AppChip(
                    label: _formatDate(_item.publishedAt),
                    icon: Icons.calendar_today_outlined,
                  ),
                ],
              ),
              if (_item.imageUrl != null &&
                  _item.imageUrl!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
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
                ),
              ],
              const SizedBox(height: 16),
              AppSectionHeader(title: 'Meldung'),
              AppCard(
                child: Text(
                  _item.body,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  Future<void> _editNews() async {
    final updated = await AppRouterScope.of(context).push<NewsItem>(
      NewsFormScreen(
        newsService: widget.newsService,
        initialItem: _item,
      ),
    );
    if (!mounted || updated == null) return;
    setState(() {
      _item = updated;
      _hasChanges = true;
    });
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('News löschen?'),
          content: const Text(
            'Möchtest du diesen Beitrag wirklich löschen? Dieser Schritt kann nicht rückgängig gemacht werden.',
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
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await widget.newsService.deleteNews(_item.id);
      if (!mounted) return;
      AppRouterScope.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Löschen fehlgeschlagen: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  Future<bool> _handleWillPop() async {
    AppRouterScope.of(context).pop(_hasChanges);
    return false;
  }
}
