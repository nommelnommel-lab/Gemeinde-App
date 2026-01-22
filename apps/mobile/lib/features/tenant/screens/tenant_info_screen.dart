import 'package:flutter/material.dart';

import '../../../config/app_config.dart';
import '../../../shared/di/app_services_scope.dart';
import '../../../shared/navigation/app_router.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemeinde-Infos'),
        actions: [
          TextButton(
            onPressed: _config == null ? null : _handleEdit,
            child: const Text('Bearbeiten'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Fehler: $_error'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _load,
            child: const Text('Erneut versuchen'),
          ),
        ],
      );
    }
    final config = _config ?? TenantConfig.empty();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'Kontakt',
          children: [
            _InfoRow(label: 'Name', value: config.name),
            _InfoRow(label: 'Adresse', value: config.address),
            _InfoRow(label: 'Telefon', value: config.phone),
            _InfoRow(label: 'E-Mail', value: config.email),
            _InfoRow(label: 'Website', value: config.website),
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
    if (_config == null) return;
    final services = AppServicesScope.of(context);
    final adminKeyStore = services.adminKeyStore;
    final storedAdminKey = adminKeyStore.getAdminKey(AppConfig.tenantId);
    String? adminKeyOverride;
    if (storedAdminKey == null || storedAdminKey.isEmpty) {
      adminKeyOverride = await _promptAdminKey();
      if (adminKeyOverride == null) return;
    }

    final updated = await AppRouterScope.of(context).push<TenantConfig>(
      TenantConfigEditScreen(
        initialConfig: _config ?? TenantConfig.empty(),
        adminKeyOverride: adminKeyOverride,
      ),
    );

    if (updated != null && mounted) {
      setState(() => _config = updated);
    }
  }

  Future<String?> _promptAdminKey() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Admin-Schlüssel eingeben'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Admin-Schlüssel',
            ),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) {
                  return;
                }
                Navigator.of(context).pop(value);
              },
              child: const Text('Weiter'),
            ),
          ],
        );
      },
    );
    return result;
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
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(value.isEmpty ? '-' : value),
        ],
      ),
    );
  }
}
