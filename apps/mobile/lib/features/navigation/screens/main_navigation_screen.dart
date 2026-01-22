import 'package:flutter/material.dart';

import '../../../api/health_service.dart';
import '../../events/services/events_service.dart';
import '../../gemeinde_app/screens/gemeinde_app_hub_screen.dart';
import '../../mehr/screens/mehr_screen.dart';
import '../../start_feed/screens/start_feed_screen.dart';
import '../../verwaltung/screens/verwaltung_hub_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
    required this.healthService,
    required this.eventsService,
  });

  final HealthService healthService;
  final EventsService eventsService;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      StartFeedScreen(
        eventsService: widget.eventsService,
      ),
      GemeindeAppHubScreen(eventsService: widget.eventsService),
      const VerwaltungHubScreen(),
      MehrScreen(healthService: widget.healthService),
    ];

    final titles = ['Start', 'GemeindeApp', 'Verwaltung', 'Mehr'];

    return Scaffold(
      appBar: AppBar(title: Text(titles[_selectedIndex])),
      body: SafeArea(child: screens[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Start'),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            label: 'GemeindeApp',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            label: 'Verwaltung',
          ),
          NavigationDestination(icon: Icon(Icons.menu), label: 'Mehr'),
        ],
      ),
    );
  }

}
