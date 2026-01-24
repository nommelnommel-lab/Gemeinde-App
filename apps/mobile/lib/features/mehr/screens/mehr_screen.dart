import 'package:flutter/material.dart';

import '../../../shared/auth/auth_scope.dart';
import '../../../shared/auth/app_permissions.dart';
import '../../../shared/auth/permissions_service.dart';
import '../../../shared/di/app_services_scope.dart';
import '../../../shared/navigation/app_router.dart';
import '../../admin/screens/admin_panel_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../hilfe/screens/hilfe_screen.dart';
import '../../systemstatus/screens/health_screen.dart';
import '../../verwaltung/screens/tenant_info_screen.dart';
import 'tenant_selection_screen.dart';

class MehrScreen extends StatefulWidget {
  const MehrScreen({super.key});

  @override
  State<MehrScreen> createState() => _MehrScreenState();
}

class _MehrScreenState extends State<MehrScreen> {
  static const Map<String, String> _tenantLabels = {
    'demo': 'Demo',
    'hilders': 'Hilders',
    'fulda': 'Fulda',
  };

  final TextEditingController _adminKeyController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  late PermissionsService _permissionsService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final services = AppServicesScope.of(context);
    _permissionsService = services.permissionsService;
    final tenantId = services.tenantStore.resolveTenantId();
    _adminKeyController.text =
        services.adminKeyStore.getAdminKey(tenantId) ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _adminKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        AppPermissionsScope.maybePermissionsOf(context)?.canManageContent ??
            false;
    final services = AppServicesScope.of(context);
    final adminKey =
        services.adminKeyStore.getAdminKey(services.tenantStore.resolveTenantId());
    final hasAdminKey = adminKey != null && adminKey.trim().isNotEmpty;
    final authStore = AuthScope.of(context);

    return ListView(
      children: [
        if (authStore.isAuthenticated)
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(authStore.user?.displayName ?? 'Angemeldet'),
            subtitle: Text(authStore.user?.email ?? ''),
            trailing: TextButton(
              onPressed: authStore.isLoading ? null : authStore.logout,
              child: const Text('Logout'),
            ),
          )
        else
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text('Login'),
            subtitle: const Text('Jetzt anmelden'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              AppRouterScope.of(context).push(const LoginScreen());
            },
          ),
        const Divider(height: 0),
        ListTile(
          leading: const Icon(Icons.monitor_heart),
          title: const Text('Systemstatus'),
          subtitle: const Text('Backend-Status prüfen'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            AppRouterScope.of(context).push(
              const HealthScreen(),
            );
          },
        ),
        const Divider(height: 0),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Info'),
          subtitle: const Text('Wichtige Hinweise zur Gemeinde'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            AppRouterScope.of(context).push(TenantInfoScreen());
          },
        ),
        const Divider(height: 0),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Hilfe'),
          subtitle: const Text('FAQs und Kontaktmöglichkeiten'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            AppRouterScope.of(context).push(const HilfeScreen());
          },
        ),
        const Divider(height: 0),
        ValueListenableBuilder<String>(
          valueListenable:
              AppServicesScope.of(context).tenantStore.tenantIdNotifier,
          builder: (context, tenantId, _) {
            final label = _tenantLabels[tenantId] ?? tenantId;
            return ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Gemeinde wechseln'),
              subtitle: Text(label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                AppRouterScope.of(context).push(
                  const TenantSelectionScreen(),
                );
              },
            );
          },
        ),
        const Divider(height: 0),
        if (isAdmin && hasAdminKey)
          ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined),
            title: const Text('Admin'),
            subtitle: const Text('Bewohner & Aktivierungscodes verwalten'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              AppRouterScope.of(context).push(
                const AdminPanelScreen(),
              );
            },
          ),
        if (isAdmin && hasAdminKey) const Divider(height: 0),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            'Admin Key',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _adminKeyController,
                    decoration: InputDecoration(
                      labelText: 'Admin Key',
                      suffixIcon: _adminKeyController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Leeren',
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _adminKeyController.clear();
                                });
                              },
                            ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Admin: ${isAdmin ? 'Ja' : 'Nein'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _saving ? null : _applyAdminKey,
                    child: Text(_saving ? 'Wird angewendet...' : 'Apply'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _applyAdminKey() async {
    setState(() => _saving = true);
    try {
      final services = AppServicesScope.of(context);
      await services.adminKeyStore.setAdminKey(
        services.tenantStore.resolveTenantId(),
        _adminKeyController.text,
      );
      final permissions = await _permissionsService.getPermissions();
      if (!mounted) return;
      AppPermissionsScope.controllerOf(context).setPermissions(permissions);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
