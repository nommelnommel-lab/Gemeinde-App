import 'package:flutter/material.dart';

import '../../../shared/di/app_services_scope.dart';
import '../../../shared/navigation/app_router.dart';
import '../../../shared/utils/external_links.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_states.dart';
import '../models/verwaltung_item.dart';
import '../services/verwaltung_service.dart';

class VerwaltungItemsScreen extends StatefulWidget {
  const VerwaltungItemsScreen({
    super.key,
    required this.kind,
  });

  final VerwaltungItemKind kind;

  @override
  State<VerwaltungItemsScreen> createState() => _VerwaltungItemsScreenState();
}

class _VerwaltungItemsScreenState extends State<VerwaltungItemsScreen> {
  late final VerwaltungService _verwaltungService;
  late final TextEditingController _searchController;
  bool _initialized = false;
  bool _loading = true;
  String? _error;
  List<VerwaltungItem> _items = const [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_handleSearchChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _verwaltungService = AppServicesScope.of(context).verwaltungService;
    _initialized = true;
    _load();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChange)
      ..dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _verwaltungService.getItems(kind: widget.kind);
      if (!mounted) return;
      setState(() {
        _items = items;
      });
    } catch (error) {
      setState(
        () => _error =
            'Verwaltungsinhalte konnten nicht geladen werden. Bitte später erneut versuchen.',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _handleSearchChange() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Text(widget.kind.label),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRouterScope.of(context).pop(),
        ),
      ),
      padBody: false,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return _buildStateList(
        const LoadingState(message: 'Verwaltungsinhalte werden geladen...'),
      );
    }

    if (_error != null) {
      return _buildStateList(
        ErrorState(
          message: _error!,
          onRetry: _load,
        ),
      );
    }

    final filtered = _filteredItems();
    if (filtered.isEmpty) {
      return _buildStateList(
        const EmptyState(
          icon: Icons.description_outlined,
          title: 'Keine Einträge gefunden',
          message: 'Für diese Auswahl liegen aktuell keine Inhalte vor.',
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildSearchField(),
        const SizedBox(height: 12),
        _buildCategoryChips(),
        const SizedBox(height: 12),
        ...filtered.map(_buildItemCard),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: 'Suchen nach Titel, Stichwort oder Kategorie',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = _categoryOptions();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final isSelected = category == _selectedCategory;
        return ChoiceChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              _selectedCategory = isSelected ? null : category;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildItemCard(VerwaltungItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () => openExternalLink(context, item.url),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title.isEmpty ? 'Unbenannter Eintrag' : item.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (item.description.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: -6,
              children: [
                _TagChip(label: item.category),
                ...item.tags.take(3).map((tag) => _TagChip(label: tag)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateList(Widget child) {
    return ListView(
      padding: const EdgeInsets.all(24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        child,
      ],
    );
  }

  List<String> _categoryOptions() {
    final categories = _items.map((item) => item.category).toSet().toList();
    categories.sort((a, b) => a.compareTo(b));
    return categories;
  }

  List<VerwaltungItem> _filteredItems() {
    final query = _searchController.text.trim().toLowerCase();
    return _items.where((item) {
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      final haystack = [
        item.title,
        item.description,
        item.category,
        item.tags.join(' '),
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall,
      ),
    );
  }
}
