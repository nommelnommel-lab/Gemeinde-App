import 'package:flutter/material.dart';

import '../../gemeinde_app/screens/gemeinde_app_hub_screen.dart';
import '../../mehr/screens/mehr_screen.dart';
import '../../start/screens/start_screen.dart';
import '../../tourism/screens/tourism_hub_screen.dart';
import '../../verwaltung/screens/verwaltung_hub_screen.dart';
import '../../warnings/screens/warnings_screen.dart';
import '../../../shared/auth/app_permissions.dart';
import '../../../shared/tenant/tenant_settings_scope.dart';
import '../../../shared/tenant/tenant_settings_store.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final settingsStore = TenantSettingsScope.of(context);
    final showWarnings = settingsStore.isFeatureEnabled('warnings');
    final showGemeindeApp = _isAnyEnabled(settingsStore, const [
      'events',
      'posts',
      'services',
      'places',
      'clubs',
      'waste',
    ]);
    final showVerwaltung = _isAnyEnabled(settingsStore, const [
      'services',
      'places',
      'waste',
    ]);
    final permissions = AppPermissionsScope.maybePermissionsOf(context);
    final isTourist = permissions?.role == 'TOURIST';

    final items = isTourist
        ? <_NavItem>[
            _NavItem(
              title: 'Start',
              screen: StartFeedScreen(onSelectTab: _onSelectTab),
              destination: const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: 'Start',
              ),
            ),
            if (showWarnings)
              _NavItem(
                title: 'Warnungen',
                screen: const WarningsScreen(),
                destination: const NavigationDestination(
                  icon: Icon(Icons.warning_amber_outlined),
                  label: 'Warnungen',
                ),
              ),
            _NavItem(
              title: 'Tourismus',
              screen: const TourismHubScreen(),
              destination: const NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                label: 'Tourismus',
              ),
            ),
            if (showVerwaltung)
              _NavItem(
                title: 'Verwaltung',
                screen: const VerwaltungHubScreen(),
                destination: const NavigationDestination(
                  icon: Icon(Icons.admin_panel_settings_outlined),
                  label: 'Verwaltung',
                ),
              ),
            _NavItem(
              title: 'Mehr',
              screen: const MehrScreen(),
              destination: const NavigationDestination(
                icon: Icon(Icons.menu),
                label: 'Mehr',
              ),
            ),
          ]
        : <_NavItem>[
            _NavItem(
              title: 'Start',
              screen: StartFeedScreen(onSelectTab: _onSelectTab),
              destination: const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: 'Start',
              ),
            ),
            if (showWarnings)
              _NavItem(
                title: 'Warnungen',
                screen: const WarningsScreen(),
                destination: const NavigationDestination(
                  icon: Icon(Icons.warning_amber_outlined),
                  label: 'Warnungen',
                ),
              ),
            if (showGemeindeApp)
              _NavItem(
                title: 'GemeindeApp',
                screen: const GemeindeAppHubScreen(),
                destination: const NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  label: 'GemeindeApp',
                ),
              ),
            if (showVerwaltung)
              _NavItem(
                title: 'Verwaltung',
                screen: const VerwaltungHubScreen(),
                destination: const NavigationDestination(
                  icon: Icon(Icons.admin_panel_settings_outlined),
                  label: 'Verwaltung',
                ),
              ),
            _NavItem(
              title: 'Mehr',
              screen: const MehrScreen(),
              destination: const NavigationDestination(
                icon: Icon(Icons.menu),
                label: 'Mehr',
              ),
            ),
          ];

    final selectedIndex = items.isEmpty
        ? 0
        : _selectedIndex.clamp(0, items.length - 1);

    return Scaffold(
      appBar: items.isEmpty
          ? null
          : AppBar(
              title: Text(items[selectedIndex].title),
              actions: [
                if (permissions?.isStaffMode ?? false)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.deepOrange.shade200),
                        ),
                        child: const Text(
                          'Staff-Modus',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      body: items.isEmpty
          ? const SizedBox.shrink()
          : SafeArea(child: items[selectedIndex].screen),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index != _selectedIndex) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
          setState(() => _selectedIndex = index);
        },
        destinations: items.map((item) => item.destination).toList(),
      ),
    );
  }

  void _onSelectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  bool _isAnyEnabled(TenantSettingsStore store, List<String> keys) {
    for (final key in keys) {
      if (store.isFeatureEnabled(key)) {
        return true;
      }
    }
    return false;
  }
}

class _NavItem {
  const _NavItem({
    required this.title,
    required this.screen,
    required this.destination,
  });

  final String title;
  final Widget screen;
  final NavigationDestination destination;
}
