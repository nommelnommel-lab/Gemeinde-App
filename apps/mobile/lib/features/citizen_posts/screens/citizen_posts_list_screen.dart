import 'package:flutter/material.dart';

import '../../../shared/auth/app_permissions.dart';
import '../../../shared/auth/auth_scope.dart';
import '../../../shared/navigation/app_router.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../../../shared/widgets/app_states.dart';
import '../../auth/screens/login_screen.dart';
import '../models/citizen_post.dart';
import '../services/citizen_posts_service.dart';
import 'citizen_post_detail_screen.dart';
import 'citizen_post_form_screen.dart';

class CitizenPostsListScreen extends StatefulWidget {
  const CitizenPostsListScreen({
    super.key,
    required this.title,
    required this.types,
    required this.postsService,
    this.filterTypes = const [],
  });

  final String title;
  final List<CitizenPostType> types;
  final CitizenPostsService postsService;
  final List<CitizenPostType> filterTypes;

  @override
  State<CitizenPostsListScreen> createState() => _CitizenPostsListScreenState();
}

class _CitizenPostsListScreenState extends State<CitizenPostsListScreen> {
  static const _emptyHint =
      'Einträge können von der Verwaltung im Web-Admin ergänzt werden.';
  bool _initialized = false;
  bool _loading = true;
  String? _error;
  bool _onlyMine = false;
  List<CitizenPost> _posts = const [];
  late final TextEditingController _searchController;
  late final List<CitizenPostType> _baseTypes;
  late final List<CitizenPostType> _filterTypes;
  CitizenPostType? _selectedType;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _baseTypes = widget.types.toSet().toList();
    _filterTypes = widget.filterTypes.isEmpty
        ? CitizenPostType.values
        : widget.filterTypes.toSet().toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authStore = AuthScope.of(context);
      final authorUserId = authStore.user?.id;
      final activeTypes = _activeTypes;
      final query = _searchController.text.trim();
      final posts = await widget.postsService.getPostsForTypes(
        types: activeTypes,
        query: query.isEmpty ? null : query,
      );
      final visiblePosts = _onlyMine && authorUserId != null
          ? posts
              .where(
                (post) => post.authorUserId == authorUserId,
              )
              .toList()
          : posts;
      if (mounted) {
        setState(() => _posts = visiblePosts);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Beiträge konnten nicht geladen werden.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = AppPermissionsScope.maybePermissionsOf(context);
    final canCreate = _canCreate(permissions);
    final authStore = AuthScope.of(context);
    final canFilterMine =
        authStore.isAuthenticated && authStore.user?.id != null;
    final currentTitle = _currentTitle;

    return AppScaffold(
      appBar: AppBar(title: Text(currentTitle)),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _openCreate,
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
            AppSectionHeader(
              title: currentTitle,
              subtitle: _currentSubtitle(),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _load(),
                    decoration: InputDecoration(
                      labelText: 'Suche',
                      suffixIcon: IconButton(
                        onPressed: _load,
                        icon: const Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CitizenPostType?>(
                    value: _selectedType,
                    decoration: const InputDecoration(labelText: 'Typ'),
                    items: [
                      const DropdownMenuItem<CitizenPostType?>(
                        value: null,
                        child: Text('Alle Typen'),
                      ),
                      ..._filterTypes.map(
                        (type) => DropdownMenuItem<CitizenPostType?>(
                          value: type,
                          child: Text(type.label),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedType = value);
                      _load();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (canFilterMine)
              AppCard(
                padding: const EdgeInsets.all(0),
                child: SwitchListTile(
                  title: const Text('Nur meine'),
                  subtitle: const Text('Nur eigene Beiträge anzeigen.'),
                  value: _onlyMine,
                  onChanged: (value) {
                    setState(() => _onlyMine = value);
                    _load();
                  },
                ),
              ),
            if (canFilterMine) const SizedBox(height: 12),
            if (_loading)
              const LoadingState(message: 'Beiträge werden geladen...')
            else if (_error != null)
              _buildErrorState()
            else if (_posts.isEmpty)
              EmptyState(
                icon: Icons.forum_outlined,
                title: 'Noch keine Einträge',
                message: _emptyMessage(),
                hint: _emptyHint,
              )
            else
              ..._posts.map(
                (post) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: () => _openDetail(post),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _subtitle(post),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AppChip(
                              label: post.type.label,
                              icon: Icons.local_activity_outlined,
                            ),
                            AppChip(
                              label: _formatDate(
                                post.createdAt.toIso8601String(),
                              ),
                              icon: Icons.calendar_today_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _emptyMessage() {
    final label = _currentTitle;
    if (_onlyMine) {
      return 'Du hast noch keine Beiträge in $label.';
    }
    return 'Noch keine Beiträge in $label.';
  }

  String _subtitle(CitizenPost post) {
    final metadata = post.metadata;
    final details = <String>[];

    final dateValue = metadata['dateTime'] ?? metadata['date'];
    if (dateValue is String && dateValue.isNotEmpty) {
      details.add(_formatDate(dateValue));
    }
    final location = metadata['location']?.toString().trim();
    if (location != null && location.isNotEmpty) {
      details.add(location);
    }
    final preview = post.body.trim();
    final trimmed = preview.length > 60
        ? '${preview.substring(0, 60)}…'
        : preview;
    if (details.isNotEmpty) {
      return '${details.join(' · ')}\n$trimmed';
    }
    return trimmed;
  }

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    final hours = parsed.hour.toString().padLeft(2, '0');
    final minutes = parsed.minute.toString().padLeft(2, '0');
    if (parsed.hour == 0 && parsed.minute == 0) {
      return '$day.$month.$year';
    }
    return '$day.$month.$year · $hours:$minutes';
  }

  String get _currentTitle =>
      _selectedType?.label ?? widget.title;

  String _currentSubtitle() {
    final activeTypes = _activeTypes;
    if (activeTypes.length <= 1) {
      return 'Austausch und Hilfe in der Gemeinde.';
    }
    final labels = activeTypes.map((type) => type.label).join(', ');
    return 'Umfasst: $labels';
  }

  List<CitizenPostType> get _activeTypes {
    if (_selectedType != null) {
      return [_selectedType!];
    }
    return _baseTypes;
  }

  bool _canCreate(AppPermissions? permissions) {
    return _creatableTypes(permissions).isNotEmpty;
  }

  List<CitizenPostType> _creatableTypes(AppPermissions? permissions) {
    final create = permissions?.canCreate;
    if (create == null) {
      return const [];
    }
    return _activeTypes
        .where((type) => _canCreateType(type, create))
        .toList();
  }

  bool _canCreateType(CitizenPostType type, CreatePermissions create) {
    switch (type) {
      case CitizenPostType.userPost:
        return false;
      case CitizenPostType.marketplace:
        return create.marketplace;
      case CitizenPostType.movingClearance:
        return create.movingClearance;
      case CitizenPostType.help:
        return create.help;
      case CitizenPostType.cafeMeetup:
        return create.cafeMeetup;
      case CitizenPostType.kidsMeetup:
        return create.kidsMeetup;
      case CitizenPostType.apartmentSearch:
        return create.apartmentSearch;
      case CitizenPostType.lostFound:
        return create.lostFound;
      case CitizenPostType.rideSharing:
        return create.rideSharing;
      case CitizenPostType.jobsLocal:
        return create.jobsLocal;
      case CitizenPostType.volunteering:
        return create.volunteering;
      case CitizenPostType.giveaway:
        return create.giveaway;
      case CitizenPostType.skillExchange:
        return create.skillExchange;
    }
  }

  Future<void> _openDetail(CitizenPost post) async {
    final result = await AppRouterScope.of(context).push<bool>(
      CitizenPostDetailScreen(
        post: post,
        postsService: widget.postsService,
      ),
    );
    if (result == true) {
      _load();
    }
  }

  Future<void> _openCreate() async {
    final permissions = AppPermissionsScope.maybePermissionsOf(context);
    final creatableTypes = _creatableTypes(permissions);
    if (creatableTypes.isEmpty) {
      return;
    }
    CitizenPostType? selectedType;
    if (creatableTypes.length == 1) {
      selectedType = creatableTypes.first;
    } else {
      selectedType = await _selectCreateType(creatableTypes);
    }
    if (selectedType == null) {
      return;
    }
    final result = await AppRouterScope.of(context).push<CitizenPost?>(
      CitizenPostFormScreen(
        type: selectedType,
        postsService: widget.postsService,
      ),
    );
    if (result != null) {
      _load();
    }
  }

  Future<CitizenPostType?> _selectCreateType(
    List<CitizenPostType> types,
  ) {
    return showDialog<CitizenPostType>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Was möchtest du erstellen?'),
        children: types
            .map(
              (type) => SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(type),
                child: Text(type.createLabel),
              ),
            )
            .toList(),
      ),
    );
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
