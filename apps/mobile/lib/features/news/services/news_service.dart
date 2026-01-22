import '../models/news_item.dart';

class NewsService {
  NewsService({this.isAdmin = true}) : _newsStore = [..._stubNews];

  final bool isAdmin;
  final List<NewsItem> _newsStore;

  static const String newsEndpoint = '/news';
  static String newsByIdEndpoint(String id) => '/news/$id';

  /// Endpoint: GET /news
  Future<List<NewsItem>> getNews() async {
    return List<NewsItem>.unmodifiable(_newsStore);
  }

  /// Endpoint: POST /news
  Future<NewsItem> createNews({
    required String title,
    required String category,
    required String body,
  }) async {
    _assertAdminAccess();
    final item = NewsItem(
      id: 'news-${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      excerpt: _createExcerpt(body),
      body: body.trim(),
      publishedAt: DateTime.now(),
      category: category.trim(),
    );
    _newsStore.add(item);
    return item;
  }

  /// Endpoint: PUT /news/:id
  Future<NewsItem> updateNews({
    required String id,
    required String title,
    required String category,
    required String body,
  }) async {
    _assertAdminAccess();
    final index = _newsStore.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw StateError('News item not found');
    }
    final updated = _newsStore[index].copyWith(
      title: title.trim(),
      excerpt: _createExcerpt(body),
      body: body.trim(),
      category: category.trim(),
    );
    _newsStore[index] = updated;
    return updated;
  }

  /// Endpoint: DELETE /news/:id
  Future<void> deleteNews(String id) async {
    _assertAdminAccess();
    _newsStore.removeWhere((item) => item.id == id);
  }

  List<String> get availableCategories {
    final categories = _newsStore.map((item) => item.category).toSet();
    return [
      'Allgemein',
      'Verwaltung',
      'Gemeinschaft',
      'Infrastruktur',
      'Familie',
      'Kultur',
      ...categories,
    ].toSet().toList()
      ..sort();
  }

  void _assertAdminAccess() {
    if (!isAdmin) {
      throw StateError('Admin access required');
    }
  }

  String _createExcerpt(String body) {
    final trimmed = body.trim();
    if (trimmed.length <= 120) {
      return trimmed;
    }
    return '${trimmed.substring(0, 117)}...';
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
