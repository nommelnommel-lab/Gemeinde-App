import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../shared/auth/auth_scope.dart';
import '../../../shared/auth/app_permissions.dart';
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

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final permissions =
        AppPermissionsScope.maybePermissionsOf(context) ?? AppPermissions.empty;
    final isTourist = permissions.role == 'TOURIST';
    final isStaff = permissions.isStaff;
    final authStore = AuthScope.of(context);
    final touristExpiry = _formatExpiry(authStore.expiresAt);

    return ListView(
      children: [
        if (authStore.isAuthenticated)
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(authStore.user?.displayName ?? 'Angemeldet'),
            subtitle: Text(authStore.user?.email ?? ''),
            trailing: TextButton(
              onPressed: authStore.isLoading ? null : _logout,
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
        if (authStore.isAuthenticated && isTourist && touristExpiry != null)
          ListTile(
            leading: const Icon(Icons.card_membership_outlined),
            title: const Text('Tourist'),
            subtitle: Text('Gültig bis $touristExpiry'),
          ),
        if (authStore.isAuthenticated && isTourist && touristExpiry != null)
          const Divider(height: 0),
        if (isStaff)
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: Text(
              permissions.isAdmin ? 'Staff-Modus (Admin)' : 'Staff-Modus',
            ),
            subtitle: Text('Rolle: ${permissions.role}'),
          ),
        if (isStaff) const Divider(height: 0),
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
        if (kDebugMode && permissions.canManageResidents)
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
      ],
    );
  }

  Future<void> _logout() async {
    final authStore = AuthScope.of(context);
    await authStore.logout();
    if (!mounted) return;
    AppPermissionsScope.controllerOf(context)
        .setPermissions(AppPermissions.empty);
  }

  String? _formatExpiry(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return null;
    }
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    return '$day.$month.$year';
  }
}
