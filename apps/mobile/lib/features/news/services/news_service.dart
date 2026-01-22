import '../../../api/api_client.dart';
import '../models/news_item.dart';

class NewsService {
  NewsService([ApiClient? apiClient])
      : _apiClient = apiClient ?? ApiClient.platform();

  final ApiClient _apiClient;

  /// Usage idea for StartFeed:
  /// ```dart
  /// final news = await NewsService().getNews();
  /// // setState(() => _news = news);
  /// ```
  Future<List<NewsItem>> getNews() async {
    assert(_apiClient.baseUrl.isNotEmpty);
    return List<NewsItem>.unmodifiable(_stubNews);
  }
}

final List<NewsItem> _stubNews = [
  NewsItem(
    id: 'news-1',
    title: 'Neue Öffnungszeiten im Bürgerbüro',
    excerpt:
        'Ab nächster Woche ist das Bürgerbüro dienstags länger geöffnet.',
    body:
        'Das Bürgerbüro erweitert seine Öffnungszeiten: Dienstags ist der '
        'Service künftig bis 19:00 Uhr geöffnet. Damit sollen Terminvergaben '
        'flexibler werden und Berufstätige besser erreicht werden.',
    publishedAt: DateTime(2024, 9, 12),
    category: 'Verwaltung',
  ),
  NewsItem(
    id: 'news-2',
    title: 'Herbstmarkt auf dem Rathausplatz',
    excerpt: 'Regionale Stände und Musik am Samstag von 10 bis 18 Uhr.',
    body:
        'Der Herbstmarkt lädt mit regionalen Ständen, Musik und '
        'Kinderangeboten auf den Rathausplatz. Besucherinnen und Besucher '
        'können lokale Produkte entdecken und bei Live-Musik verweilen.',
    publishedAt: DateTime(2024, 9, 14),
    category: 'Gemeinschaft',
    imageUrl:
        'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0',
  ),
  NewsItem(
    id: 'news-3',
    title: 'Sanierung der Hauptstraße',
    excerpt: 'Kurzfristige Umleitungen wegen Asphaltarbeiten einplanen.',
    body:
        'Ab Mitte September wird die Hauptstraße abschnittsweise saniert. '
        'Bitte beachten Sie die ausgeschilderten Umleitungen und planen Sie '
        'mehr Zeit für Ihre Wege ein.',
    publishedAt: DateTime(2024, 9, 16),
    category: 'Infrastruktur',
  ),
  NewsItem(
    id: 'news-4',
    title: 'Mehr Grünflächen am Spielplatz',
    excerpt: 'Neue Sitzbereiche und Schattenplätze werden eingerichtet.',
    body:
        'Der Spielplatz am Stadtpark bekommt zusätzliche Sitzbereiche und '
        'Schattenplätze. Die Arbeiten beginnen in der kommenden Woche und '
        'sollen bis zum Monatsende abgeschlossen sein.',
    publishedAt: DateTime(2024, 9, 18),
    category: 'Familie',
  ),
  NewsItem(
    id: 'news-5',
    title: 'Stadtbibliothek feiert Jubiläum',
    excerpt: 'Lesungen und Aktionen im Rahmen der Jubiläumswoche.',
    body:
        'Die Stadtbibliothek feiert ihr Jubiläum mit einer Aktionswoche. '
        'Auf dem Programm stehen Lesungen, Workshops und eine Mitmach-Ecke '
        'für Kinder.',
    publishedAt: DateTime(2024, 9, 20),
    category: 'Kultur',
  ),
];
