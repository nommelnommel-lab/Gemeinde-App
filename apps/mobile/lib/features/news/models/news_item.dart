class NewsItem {
  const NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.publishedAt,
  });

  final String id;
  final String title;
  final String summary;
  final DateTime publishedAt;
}
