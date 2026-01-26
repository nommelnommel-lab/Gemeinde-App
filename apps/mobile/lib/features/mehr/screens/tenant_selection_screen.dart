import 'package:flutter/material.dart';

import '../../../shared/di/app_services_scope.dart';
import '../../../shared/navigation/app_router.dart';
import '../../../shared/tenant/tenant_store.dart';

class TenantSelectionScreen extends StatelessWidget {
  const TenantSelectionScreen({super.key});

  static const List<_TenantOption> _options = [
    _TenantOption(id: 'demo', name: 'Demo'),
    _TenantOption(id: 'hilders-demo', name: 'Hilders Demo'),
    _TenantOption(id: 'hilders', name: 'Hilders'),
    _TenantOption(id: 'fulda', name: 'Fulda'),
  ];

  static final RegExp _tenantIdPattern = RegExp(r'^[a-z0-9-]{1,40}$');

  @override
  Widget build(BuildContext context) {
    final tenantStore = AppServicesScope.of(context).tenantStore;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemeinde wechseln'),
      ),
      body: ValueListenableBuilder<String>(
        valueListenable: tenantStore.tenantIdNotifier,
        builder: (context, currentTenantId, _) {
          return ListView.separated(
            itemCount: _options.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final option = _options[index];
              final isSelected = option.id == currentTenantId;
              return ListTile(
                title: Text(option.name),
                subtitle: Text(option.id),
                trailing:
                    isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () => _selectTenant(
                  context,
                  tenantStore,
                  option.id,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _selectTenant(
    BuildContext context,
    TenantStore tenantStore,
    String tenantId,
  ) async {
    if (!_tenantIdPattern.hasMatch(tenantId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ungültige Gemeinde-ID.')),
      );
      return;
    }

    await tenantStore.setTenantId(tenantId);
    AppRouterScope.of(context).pop();
  }
}

class _TenantOption {
  const _TenantOption({required this.id, required this.name});

  final String id;
  final String name;
}
