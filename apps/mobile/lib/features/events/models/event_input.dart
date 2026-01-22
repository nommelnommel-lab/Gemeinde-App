class EventInput {
  const EventInput({
    required this.title,
    required this.description,
    required this.date,
    required this.location,
  });

  final String title;
  final String description;
  final DateTime date;
  final String location;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'location': location,
    };
  }
}
