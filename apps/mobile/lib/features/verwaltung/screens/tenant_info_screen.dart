import 'package:flutter/material.dart';

import '../../../shared/di/app_services_scope.dart';
import '../models/tenant_config.dart';
import '../services/tenant_config_service.dart';

class TenantInfoScreen extends StatefulWidget {
  const TenantInfoScreen({super.key});

  @override
  State<TenantInfoScreen> createState() => _TenantInfoScreenState();
}

class _TenantInfoScreenState extends State<TenantInfoScreen> {
  late final TenantConfigService _tenantConfigService;
  bool _initialized = false;
  bool _loading = true;
  String? _error;
  TenantConfig? _config;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _tenantConfigService = AppServicesScope.of(context).tenantConfigService;
    _initialized = true;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final config = await _tenantConfigService.getTenantConfig();
      if (!mounted) return;
      setState(() => _config = config);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = _loading && _config == null
        ? _StatusCard(
            title: 'Daten werden geladen',
            description: 'Bitte einen Moment Geduld.',
            trailing: const Padding(
              padding: EdgeInsets.only(top: 8),
              child: CircularProgressIndicator(),
            ),
          )
        : _error != null && _config == null
            ? _StatusCard(
                title: 'Daten konnten nicht geladen werden',
                description: _error ?? 'Unbekannter Fehler',
                trailing: FilledButton(
                  onPressed: _load,
                  child: const Text('Erneut versuchen'),
                ),
              )
            : _buildContent(theme);

    return Scaffold(
      appBar: AppBar(title: const Text('Öffnungszeiten & Kontakt')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [body],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final config = _config;
    if (config == null) {
      return const SizedBox.shrink();
    }

    final openingHoursByDay = <String, List<String>>{};
    for (final entry in config.openingHours) {
      final dayKey = entry.day.isNotEmpty ? entry.day : 'Unbekannt';
      openingHoursByDay.putIfAbsent(dayKey, () => []).addAll(entry.hours);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.name,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(config.address.isNotEmpty
                    ? config.address
                    : 'Keine Adresse hinterlegt'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _InfoSection(
          title: 'Kontakt',
          children: [
            if (config.phone != null)
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text(config.phone!),
              ),
            if (config.email != null)
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: Text(config.email!),
              ),
            if (config.website != null)
              ListTile(
                leading: const Icon(Icons.public_outlined),
                title: Text(config.website!),
              ),
            if (config.phone == null &&
                config.email == null &&
                config.website == null)
              const ListTile(
                title: Text('Keine Kontaktdaten hinterlegt.'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _InfoSection(
          title: 'Öffnungszeiten',
          children: openingHoursByDay.isEmpty
              ? const [
                  ListTile(
                    title: Text('Keine Öffnungszeiten hinterlegt.'),
                  )
                ]
              : openingHoursByDay.entries
                  .map(
                    (entry) => ListTile(
                      title: Text(entry.key),
                      subtitle: entry.value.isEmpty
                          ? const Text('Keine Zeiten hinterlegt')
                          : Text(entry.value.join(', ')),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 12),
        _InfoSection(
          title: 'Notrufnummern',
          children: config.emergencyNumbers.isEmpty
              ? const [
                  ListTile(
                    title: Text('Keine Notrufnummern hinterlegt.'),
                  )
                ]
              : config.emergencyNumbers
                  .map(
                    (entry) => ListTile(
                      leading: const Icon(Icons.warning_amber_outlined),
                      title: Text(entry.label),
                      subtitle: Text(entry.number),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.description,
    required this.trailing,
  });

  final String title;
  final String description;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(description, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
