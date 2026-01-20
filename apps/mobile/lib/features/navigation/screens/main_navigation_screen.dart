import 'package:flutter/material.dart';

import '../../../api/health_service.dart';
import '../../events/services/events_service.dart';
import '../../events/screens/events_screen.dart';
import '../../hilfe/screens/hilfe_screen.dart';
import '../../info/screens/info_screen.dart';
import '../../mehr/screens/mehr_screen.dart';

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
      const InfoScreen(),
      const HilfeScreen(),
      EventsScreen(eventsService: widget.eventsService),
      MehrScreen(healthService: widget.healthService),
    ];

    final titles = ['Info', 'Hilfe', 'Events', 'Mehr'];

    return Scaffold(
      appBar: AppBar(title: Text(titles[_selectedIndex])),
      body: SafeArea(child: screens[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.info_outline), label: 'Info'),
          NavigationDestination(icon: Icon(Icons.help_outline), label: 'Hilfe'),
          NavigationDestination(icon: Icon(Icons.event), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.menu), label: 'Mehr'),
        ],
      ),
    );
  }
}
