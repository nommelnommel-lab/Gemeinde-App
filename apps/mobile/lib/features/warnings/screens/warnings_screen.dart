import 'package:flutter/material.dart';

import '../../../shared/di/app_services_scope.dart';
import '../../../shared/navigation/app_router.dart';
import '../models/warning_item.dart';
import '../services/warnings_service.dart';
import '../utils/warning_formatters.dart';
import 'warning_detail_screen.dart';

class WarningsScreen extends StatefulWidget {
  const WarningsScreen({
    super.key,
    this.warningsService,
  });

  final WarningsService? warningsService;

  @override
  State<WarningsScreen> createState() => _WarningsScreenState();
}

class _WarningsScreenState extends State<WarningsScreen> {
  late WarningsService _warningsService;
  bool _initialized = false;
  bool _loading = true;
  String? _error;
  List<WarningItem> _warnings = const [];
  WarningFilter _selectedFilter = WarningFilter.all;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _warningsService =
        widget.warningsService ?? AppServicesScope.of(context).warningsService;
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
    } catch (e) {
      setState(() => _error = e.toString());
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
              const Text('Aktuell liegen keine Warnungen vor.')
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
                    onTap: () => AppRouterScope.of(context).push(
                      WarningDetailScreen(warning: warning),
                    ),
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
