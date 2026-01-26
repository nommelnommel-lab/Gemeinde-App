import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../shared/di/app_services_scope.dart';
import '../../../shared/navigation/app_router.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_states.dart';
import '../models/tourism_item.dart';
import '../services/tourism_service.dart';
import 'tourism_detail_screen.dart';

class TourismListScreen extends StatefulWidget {
  const TourismListScreen({
    super.key,
    required this.type,
  });

  final TourismItemType type;

  @override
  State<TourismListScreen> createState() => _TourismListScreenState();
}

class _TourismListScreenState extends State<TourismListScreen> {
  late final TourismService _tourismService;
  bool _initialized = false;

  bool _loading = true;
  String? _error;
  List<TourismItem> _items = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _tourismService = AppServicesScope.of(context).tourismService;
    _initialized = true;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _tourismService.getItems(type: widget.type);
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      debugPrint('Tourism loading failed: $e');
      setState(
        () => _error =
            'Tourismus-Inhalte konnten nicht geladen werden. Bitte später erneut versuchen.',
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Text(widget.type.label),
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
        const LoadingState(message: 'Tourismus-Inhalte werden geladen...'),
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

    if (_items.isEmpty) {
      return _buildStateList(
        EmptyState(
          icon: Icons.map_outlined,
          title: 'Keine Einträge verfügbar',
          message: 'Für diese Kategorie sind aktuell keine Inhalte vorhanden.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _items[index];
        return AppCard(
          onTap: () => _openDetail(item),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title.isEmpty ? 'Unbenannter Eintrag' : item.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                _preview(item.body),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (item.metadataString('address') != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.metadataString('address')!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _preview(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= 120) {
      return trimmed;
    }
    return '${trimmed.substring(0, 117)}...';
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

  void _openDetail(TourismItem item) {
    AppRouterScope.of(context).push(
      TourismDetailScreen(item: item),
    );
  }
}
