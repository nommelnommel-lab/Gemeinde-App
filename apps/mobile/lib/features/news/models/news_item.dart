class NewsItem {
  const NewsItem({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.body,
    required this.publishedAt,
    required this.category,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String excerpt;
  final String body;
  final DateTime publishedAt;
  final String category;
  final String? imageUrl;

  String get summary => excerpt;
  DateTime get createdAt => publishedAt;

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    final publishedValue = json['publishedAt'] ?? json['createdAt'];
    return NewsItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      excerpt: json['excerpt'] as String? ?? '',
      body: json['body'] as String? ?? '',
      publishedAt: _parseDateTime(publishedValue),
      category: json['category'] as String? ?? 'Allgemein',
      imageUrl: json['imageUrl'] as String?,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  NewsItem copyWith({
    String? id,
    String? title,
    String? excerpt,
    String? body,
    DateTime? publishedAt,
    String? category,
    String? imageUrl,
  }) {
    return NewsItem(
      id: id ?? this.id,
      title: title ?? this.title,
      excerpt: excerpt ?? this.excerpt,
      body: body ?? this.body,
      publishedAt: publishedAt ?? this.publishedAt,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
