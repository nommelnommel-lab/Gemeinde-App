import 'package:flutter/material.dart';

import '../../../shared/auth/app_permissions.dart';
import '../../../shared/auth/auth_scope.dart';
import '../../../shared/di/app_services_scope.dart';
import '../../../shared/navigation/app_router.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_states.dart';
import '../../auth/screens/login_screen.dart';
import '../models/news_item.dart';
import '../services/news_service.dart';
import 'news_form_screen.dart';
import 'news_detail_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late final NewsService _newsService;
  bool _initialized = false;
  bool _canManageContent = false;
  bool _loading = true;
  String? _error;
  List<NewsItem> _news = const [];
  String _searchTerm = '';
  String _selectedCategory = 'Alle';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _newsService = AppServicesScope.of(context).newsService;
      _initialized = true;
      _load();
    }
    final permissions =
        AppPermissionsScope.maybePermissionsOf(context) ?? AppPermissions.empty;
    final isAuthenticated = AuthScope.of(context).isAuthenticated;
    _canManageContent = isAuthenticated && permissions.canCreate.officialNews;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final news = await _newsService.getNews();
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
    return AppScaffold(
      appBar: AppBar(
        title: const Text('News'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRouterScope.of(context).pop(),
        ),
      ),
      floatingActionButton: _canManageContent
          ? FloatingActionButton.extended(
              onPressed: _openCreateNews,
              icon: const Icon(Icons.add),
              label: const Text('Hinzufügen'),
            )
          : null,
      padBody: false,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
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
              const LoadingState(message: 'News werden geladen...')
            else if (_error != null)
              _buildErrorState()
            else if (_filteredNews.isEmpty)
              EmptyState(
                icon: Icons.article_outlined,
                title: 'Keine News gefunden',
                message: _emptyMessage(),
              )
            else
              ..._filteredNews.map(
                (item) => Card(
                  child: ListTile(
                    title: Text(item.title),
                    subtitle: Text(
                      '${_formatDate(item.publishedAt)} · ${item.excerpt}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final updated =
                          await AppRouterScope.of(context).push<bool>(
                        NewsDetailScreen(
                          item: item,
                          newsService: _newsService,
                          canEdit: _canManageContent,
                        ),
                      );
                      if (!mounted) return;
                      if (updated == true) {
                        await _load();
                      }
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateNews() async {
    final created = await AppRouterScope.of(context).push<NewsItem>(
      NewsFormScreen(newsService: _newsService),
    );
    if (!mounted || created == null) {
      return;
    }
    setState(() {
      _news = [..._news, created];
    });
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

  String _emptyMessage() {
    if (_selectedCategory != 'Alle') {
      return 'Keine News in der Kategorie $_selectedCategory.';
    }
    return 'Keine News gefunden.';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  Widget _buildErrorState() {
    final normalized = _error!.toLowerCase();
    final isAuthError = normalized.contains('http 401') ||
        normalized.contains('http 403') ||
        normalized.contains('sitzung abgelaufen');
    return ErrorState(
      message: _error!,
      onRetry: _load,
      secondaryAction: isAuthError
          ? OutlinedButton(
              onPressed: () {
                AppRouterScope.of(context).push(const LoginScreen());
              },
              child: const Text('Anmelden'),
            )
          : null,
    );
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
