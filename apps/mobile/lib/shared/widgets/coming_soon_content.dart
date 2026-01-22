import 'package:flutter/material.dart';

class ComingSoonContent extends StatelessWidget {
  const ComingSoonContent({
    super.key,
    required this.description,
  });

  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kommt bald', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(description, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
