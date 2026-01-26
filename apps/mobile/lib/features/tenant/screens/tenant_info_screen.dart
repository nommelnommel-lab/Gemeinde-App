import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../shared/di/app_services_scope.dart';
import '../../../shared/navigation/app_router.dart';
import '../../../shared/utils/external_links.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_states.dart';
import '../models/tenant_config.dart';
import '../services/tenant_service.dart';
import 'tenant_config_edit_screen.dart';

class TenantInfoScreen extends StatefulWidget {
  const TenantInfoScreen({super.key});

  @override
  State<TenantInfoScreen> createState() => _TenantInfoScreenState();
}

class _TenantInfoScreenState extends State<TenantInfoScreen> {
  bool _initialized = false;
  bool _loading = true;
  String? _error;
  TenantConfig? _config;
  late TenantService _tenantService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _tenantService = AppServicesScope.of(context).tenantService;
    _initialized = true;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final config = await _tenantService.getTenantConfig();
      if (!mounted) return;
      setState(() => _config = config);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Gemeinde-Infos'),
        actions: [
          if (!kReleaseMode)
            TextButton(
              onPressed: _config == null ? null : _handleEdit,
              child: const Text('Bearbeiten'),
            ),
        ],
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
        const LoadingState(message: 'Gemeinde-Infos werden geladen...'),
      );
    }
    if (_error != null) {
      return _buildStateList(
        ErrorState(message: _error!, onRetry: _load),
      );
    }
    final config = _config ?? TenantConfig.empty();
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _SectionCard(
          title: 'Kontakt',
          children: [
            _InfoRow(label: 'Name', value: config.name),
            _InfoRow(label: 'Adresse', value: config.address),
            _InfoRow(label: 'Telefon', value: config.phone),
            _InfoRow(label: 'E-Mail', value: config.email),
            _InfoRow(
              label: 'Website',
              value: config.website,
              onTap: config.website.isEmpty
                  ? null
                  : () => openExternalLink(context, config.website),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Öffnungszeiten',
          children: config.openingHours.isEmpty
              ? [const Text('Keine Öffnungszeiten hinterlegt.')]
              : config.openingHours
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.day.isEmpty ? 'Unbekannter Tag' : entry.day,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.closed
                                ? 'Geschlossen'
                                : '${entry.opens} - ${entry.closes}',
                          ),
                          if (entry.note.isNotEmpty)
                            Text(
                              entry.note,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Notrufnummern',
          children: config.emergencyNumbers.isEmpty
              ? [const Text('Keine Notrufnummern hinterlegt.')]
              : config.emergencyNumbers
                  .map((number) => Text(number))
                  .toList(),
        ),
      ],
    );
  }

  Future<void> _handleEdit() async {
    if (kReleaseMode) return;
    if (_config == null) return;
    final updated = await AppRouterScope.of(context).push<TenantConfig>(
      TenantConfigEditScreen(
        initialConfig: _config ?? TenantConfig.empty(),
      ),
    );

    if (updated != null && mounted) {
      setState(() => _config = updated);
    }
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

}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (onTap != null && value.isNotEmpty)
            InkWell(
              onTap: onTap,
              child: Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            )
          else
            Text(value.isEmpty ? '-' : value),
        ],
      ),
    );
  }
}
