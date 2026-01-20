import 'package:flutter/material.dart';

import '../../../shared/widgets/placeholder_content.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderContent(
      title: 'Events',
      description:
          'Hier erscheinen bald die nächsten Veranstaltungen und Termine.',
    );
  }
}
