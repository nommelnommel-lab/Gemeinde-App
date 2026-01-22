import '../models/news_item.dart';

class NewsService {
  /// Usage idea for StartFeed:
  /// ```dart
  /// final news = await NewsService().getNews();
  /// // setState(() => _news = news);
  /// ```
  Future<List<NewsItem>> getNews() async {
    return List<NewsItem>.unmodifiable(_stubNews);
  }
}

final List<NewsItem> _stubNews = [
  NewsItem(
    id: 'news-1',
    title: 'Neue Öffnungszeiten im Bürgerbüro',
    summary: 'Ab nächster Woche ist das Bürgerbüro dienstags länger geöffnet.',
    publishedAt: DateTime(2024, 9, 12),
  ),
  NewsItem(
    id: 'news-2',
    title: 'Herbstmarkt auf dem Rathausplatz',
    summary: 'Regionale Stände und Musik am Samstag von 10 bis 18 Uhr.',
    publishedAt: DateTime(2024, 9, 14),
  ),
  NewsItem(
    id: 'news-3',
    title: 'Sanierung der Hauptstraße',
    summary: 'Kurzfristige Umleitungen wegen Asphaltarbeiten einplanen.',
    publishedAt: DateTime(2024, 9, 16),
  ),
];
