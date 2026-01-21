class Event {
  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Event.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString();
    final title = (json['title'] ?? '').toString();
    final description = (json['description'] ?? '').toString();
    final location = (json['location'] ?? '').toString();
    final dateValue = json['date'];
    final createdAtValue = json['createdAt'] ?? json['created_at'];
    final updatedAtValue = json['updatedAt'] ?? json['updated_at'];

    final parsedDate = _parseDate(dateValue);
    final parsedCreatedAt = _parseDate(createdAtValue) ?? DateTime.now();
    final parsedUpdatedAt = _parseDate(updatedAtValue) ?? DateTime.now();

    return Event(
      id: id,
      title: title,
      description: description,
      date: parsedDate ?? DateTime.now(),
      location: location,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'location': location,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return DateTime.tryParse(value.toString());
  }
}
