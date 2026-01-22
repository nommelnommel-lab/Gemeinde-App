import 'package:flutter/material.dart';

import '../models/event.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({
    super.key,
    required this.event,
  });

  final Event event;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  @override
  Widget build(BuildContext context) {
    final title = event.title.trim();
    final location = event.location.trim().isEmpty
        ? 'Ort wird noch bekannt gegeben'
        : event.location.trim();
    final description = event.description.trim().isEmpty
        ? 'Keine Beschreibung verfügbar.'
        : event.description.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(title.isEmpty ? 'Event' : title),
        leadingWidth: 96,
        leading: TextButton.icon(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Zurück'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDate(event.date),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(description, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

}
