import 'package:flutter/material.dart';

import '../../../shared/navigation/app_router.dart';
import '../models/news_item.dart';
import '../services/news_service.dart';
import 'news_detail_screen.dart';
import 'news_form_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key, required this.newsService});

  final NewsService newsService;

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  bool _loading = true;
  String? _error;
  List<NewsItem> _news = const [];
  String _searchTerm = '';
  String _selectedCategory = 'Alle';

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
      final news = await widget.newsService.getNews();
      setState(() => _news = news);
    } catch (e) {
      setState(
        () => _error =
            'News konnten nicht geladen werden. Bitte später erneut versuchen.',
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.newsService.isAdmin
          ? FloatingActionButton.extended(
              onPressed: _openCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create News'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Suche',
                hintText: 'Titel oder Stichwort',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchTerm = value),
            ),
            const SizedBox(height: 12),
            _CategoryFilter(
              categories: _availableCategories,
              selected: _selectedCategory,
              onSelected: (value) => setState(() => _selectedCategory = value),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              _ErrorView(error: _error!, onRetry: _load)
            else if (_filteredNews.isEmpty)
              const Text('Keine News gefunden.')
            else
              ..._filteredNews.map(
                (item) => Card(
                  child: ListTile(
                    title: Text(item.title),
                    subtitle: Text(
                      '${_formatDate(item.publishedAt)} · ${item.excerpt}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openDetail(item),
                  ),
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  List<NewsItem> get _filteredNews {
    final query = _searchTerm.trim().toLowerCase();

    final filtered = _news.where((item) {
      if (_selectedCategory != 'Alle' &&
          item.category.toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      final haystack =
          '${item.title} ${item.excerpt} ${item.body}'.toLowerCase();
      return haystack.contains(query);
    }).toList();

    filtered.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return filtered;
  }

  List<String> get _availableCategories {
    final categories = _news.map((item) => item.category).toSet().toList()
      ..sort();
    return ['Alle', ...categories];
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  Future<void> _openCreate() async {
    final created = await AppRouterScope.of(context).push<NewsItem>(
      NewsFormScreen(newsService: widget.newsService),
    );

    if (created != null) {
      await _load();
    }
  }

  Future<void> _openDetail(NewsItem item) async {
    final shouldReload = await AppRouterScope.of(context).push<bool>(
      NewsDetailScreen(item: item, newsService: widget.newsService),
    );

    if (shouldReload == true) {
      await _load();
    }
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        return ChoiceChip(
          label: Text(category),
          selected: category == selected,
          onSelected: (_) => onSelected(category),
        );
      }).toList(),
    );
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
          mainAxisSize: MainAxisSize.min,
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
