class Event {
  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
  });

  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      location: json['location'] as String,
    );
  }
}
