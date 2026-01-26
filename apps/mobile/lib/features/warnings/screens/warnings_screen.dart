import 'package:flutter/material.dart';

import '../../../shared/auth/app_permissions.dart';
import '../../../shared/auth/auth_scope.dart';
import '../../../shared/di/app_services_scope.dart';
import '../../../shared/navigation/app_router.dart';
import '../../auth/screens/login_screen.dart';
import '../models/warning_item.dart';
import '../services/warnings_service.dart';
import '../utils/warning_formatters.dart';
import 'warning_detail_screen.dart';
import 'warning_form_screen.dart';

class WarningsScreen extends StatefulWidget {
  const WarningsScreen({super.key});

  @override
  State<WarningsScreen> createState() => _WarningsScreenState();
}

class _WarningsScreenState extends State<WarningsScreen> {
  late final WarningsService _warningsService;
  bool _initialized = false;
  bool _loading = true;
  String? _error;
  List<WarningItem> _warnings = const [];
  WarningFilter _selectedFilter = WarningFilter.all;
  bool _canManageContent = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final permissions =
        AppPermissionsScope.maybePermissionsOf(context) ?? AppPermissions.empty;
    final isAuthenticated = AuthScope.of(context).isAuthenticated;
    _canManageContent =
        isAuthenticated && permissions.canCreate.officialWarnings;
    if (_initialized) {
      return;
    }
    _warningsService = AppServicesScope.of(context).warningsService;
    _initialized = true;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final warnings = await _warningsService.getWarnings();
      setState(() => _warnings = warnings);
    } catch (_) {
      setState(
        () => _error =
            'Warnungen konnten nicht geladen werden. Bitte später erneut versuchen.',
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _applyFilter(_warnings, _selectedFilter);
    final sorted = _sortedWarnings(filtered);

    return Scaffold(
      appBar: AppBar(title: const Text('Warnungen')),
      floatingActionButton: _canManageContent
          ? FloatingActionButton.extended(
              onPressed: _openCreateWarning,
              icon: const Icon(Icons.add),
              label: const Text('Add Warning'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _FilterChips(
              selected: _selectedFilter,
              onSelected: (filter) {
                setState(() => _selectedFilter = filter);
              },
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              _WarningsErrorView(error: _error!, onRetry: _load)
            else if (sorted.isEmpty)
              Text(_emptyMessage(_selectedFilter))
            else
              ...sorted.map(
                (warning) => Card(
                  child: ListTile(
                    leading: _severityIcon(warning.severity),
                    title: Text(warning.title),
                    subtitle: Text(
                      '${warning.severity.label} · ${formatDateTime(warning.publishedAt)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final updated = await AppRouterScope.of(context).push<bool>(
                        WarningDetailScreen(
                          warning: warning,
                          warningsService: _warningsService,
                          canEdit: _canManageContent,
                        ),
                      );
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

  List<WarningItem> _sortedWarnings(List<WarningItem> warnings) {
    final indexed = warnings.asMap().entries.toList();
    indexed.sort((a, b) {
      final dateCompare =
          b.value.publishedAt.compareTo(a.value.publishedAt);
      if (dateCompare != 0) {
        return dateCompare;
      }
      return a.key.compareTo(b.key);
    });
    return indexed.map((entry) => entry.value).toList();
  }

  List<WarningItem> _applyFilter(
    List<WarningItem> warnings,
    WarningFilter filter,
  ) {
    switch (filter) {
      case WarningFilter.all:
        return warnings;
      case WarningFilter.today:
        return warnings.where(_isToday).toList();
      case WarningFilter.weather:
        return warnings.where(_isWeatherWarning).toList();
      case WarningFilter.traffic:
        return warnings.where(_isTrafficWarning).toList();
      case WarningFilter.info:
        return warnings
            .where((warning) => warning.severity == WarningSeverity.info)
            .toList();
      case WarningFilter.warning:
        return warnings
            .where((warning) => warning.severity == WarningSeverity.warning)
            .toList();
      case WarningFilter.critical:
        return warnings
            .where((warning) => warning.severity == WarningSeverity.critical)
            .toList();
    }
  }

  String _emptyMessage(WarningFilter filter) {
    switch (filter) {
      case WarningFilter.all:
        return 'Aktuell liegen keine Warnungen vor.';
      case WarningFilter.today:
        return 'Heute liegen keine Warnungen vor.';
      case WarningFilter.weather:
        return 'Keine Warnungen in der Kategorie Unwetter.';
      case WarningFilter.traffic:
        return 'Keine Warnungen in der Kategorie Verkehr.';
      case WarningFilter.info:
        return 'Keine Warnungen mit Info-Schweregrad.';
      case WarningFilter.warning:
        return 'Keine Warnungen mit Warnung-Schweregrad.';
      case WarningFilter.critical:
        return 'Keine Warnungen mit Kritisch-Schweregrad.';
    }
  }

  bool _isToday(WarningItem warning) {
    final now = DateTime.now();
    return warning.publishedAt.year == now.year &&
        warning.publishedAt.month == now.month &&
        warning.publishedAt.day == now.day;
  }

  bool _isWeatherWarning(WarningItem warning) {
    final text =
        '${warning.title} ${warning.body}'.toLowerCase();
    return text.contains('unwetter') ||
        text.contains('gewitter') ||
        text.contains('sturm') ||
        text.contains('wetter') ||
        text.contains('regen');
  }

  bool _isTrafficWarning(WarningItem warning) {
    final text =
        '${warning.title} ${warning.body}'.toLowerCase();
    return text.contains('verkehr') ||
        text.contains('straße') ||
        text.contains('strasse') ||
        text.contains('sperrung') ||
        text.contains('umleitung') ||
        text.contains('bahnhof');
  }

  Widget _severityIcon(WarningSeverity severity) {
    switch (severity) {
      case WarningSeverity.info:
        return const Icon(Icons.info_outline, color: Colors.blue);
      case WarningSeverity.warning:
        return const Icon(Icons.warning_amber, color: Colors.orange);
      case WarningSeverity.critical:
        return const Icon(Icons.report, color: Colors.red);
    }
  }

  Future<void> _openCreateWarning() async {
    final created = await AppRouterScope.of(context).push<WarningItem>(
      WarningFormScreen(warningsService: _warningsService),
    );
    if (!mounted || created == null) {
      return;
    }
    setState(() {
      _warnings = [created, ..._warnings];
    });
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.onSelected,
  });

  final WarningFilter selected;
  final ValueChanged<WarningFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: WarningFilter.values.map((filter) {
        return ChoiceChip(
          label: Text(filter.label),
          selected: selected == filter,
          labelStyle: TextStyle(
            color: selected == filter
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
          onSelected: (_) => onSelected(filter),
        );
      }).toList(),
    );
  }
}

class _WarningsErrorView extends StatelessWidget {
  const _WarningsErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final normalized = error.toLowerCase();
    final isAuthError = normalized.contains('http 401') ||
        normalized.contains('http 403') ||
        normalized.contains('sitzung abgelaufen');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Warnungen konnten nicht geladen werden.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(error),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Erneut versuchen'),
                ),
                if (isAuthError)
                  OutlinedButton(
                    onPressed: () {
                      AppRouterScope.of(context).push(const LoginScreen());
                    },
                    child: const Text('Anmelden'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum WarningFilter {
  all,
  today,
  weather,
  traffic,
  info,
  warning,
  critical,
}

extension WarningFilterLabel on WarningFilter {
  String get label {
    switch (this) {
      case WarningFilter.all:
        return 'Alle';
      case WarningFilter.today:
        return 'Heute';
      case WarningFilter.weather:
        return 'Unwetter';
      case WarningFilter.traffic:
        return 'Verkehr';
      case WarningFilter.info:
        return 'Info';
      case WarningFilter.warning:
        return 'Warnung';
      case WarningFilter.critical:
        return 'Kritisch';
    }
  }
}
