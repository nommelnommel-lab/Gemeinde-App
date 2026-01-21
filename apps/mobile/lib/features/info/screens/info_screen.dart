import 'package:flutter/material.dart';

import '../../../shared/widgets/placeholder_content.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderContent(
      title: 'Info',
      description:
          'Hier findest du künftig Informationen zur Gemeinde und aktuelle Hinweise.',
    );
  }
}
