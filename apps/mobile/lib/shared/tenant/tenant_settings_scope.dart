import 'package:flutter/material.dart';

import 'tenant_settings_store.dart';

class TenantSettingsScope extends InheritedNotifier<TenantSettingsStore> {
  const TenantSettingsScope({
    super.key,
    required TenantSettingsStore store,
    required super.child,
  }) : super(notifier: store);

  static TenantSettingsStore of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<TenantSettingsScope>();
    assert(scope != null, 'TenantSettingsScope not found in widget tree.');
    return scope!.notifier!;
  }
}
