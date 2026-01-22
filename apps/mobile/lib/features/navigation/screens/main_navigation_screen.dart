import 'package:flutter/material.dart';

import '../../../api/health_service.dart';
import '../../events/services/events_service.dart';
import '../../gemeinde_app/screens/gemeinde_app_hub_screen.dart';
import '../../mehr/screens/mehr_screen.dart';
import '../../news/services/news_service.dart';
import '../../start/screens/start_screen.dart';
import '../../verwaltung/screens/verwaltung_hub_screen.dart';
import '../../warnings/screens/warnings_screen.dart';
import '../../warnings/services/warnings_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
    required this.healthService,
    required this.eventsService,
    required this.warningsService,
    required this.newsService,
  });

  final HealthService healthService;
  final EventsService eventsService;
  final WarningsService warningsService;
  final NewsService newsService;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      StartFeedScreen(
        onSelectTab: _onSelectTab,
        eventsService: widget.eventsService,
        warningsService: widget.warningsService,
        newsService: widget.newsService,
      ),
      WarningsScreen(warningsService: widget.warningsService),
      GemeindeAppHubScreen(
        eventsService: widget.eventsService,
        newsService: widget.newsService,
      ),
      const VerwaltungHubScreen(),
      MehrScreen(healthService: widget.healthService),
    ];

    final titles = ['Start', 'Warnungen', 'GemeindeApp', 'Verwaltung', 'Mehr'];

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
            icon: Icon(Icons.warning_amber_outlined),
            label: 'Warnungen',
          ),
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

  void _onSelectTab(int index) {
    setState(() => _selectedIndex = index);
  }
}
