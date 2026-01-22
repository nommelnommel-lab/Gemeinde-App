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
}
