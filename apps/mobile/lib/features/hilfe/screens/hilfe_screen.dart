import 'package:flutter/material.dart';

import '../../../shared/widgets/placeholder_content.dart';

class HilfeScreen extends StatelessWidget {
  const HilfeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderContent(
      title: 'Hilfe',
      description:
          'Hier werden zukünftig FAQs und Kontaktmöglichkeiten bereitgestellt.',
    );
  }
}
