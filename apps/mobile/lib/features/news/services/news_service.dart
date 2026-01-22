import '../../../api/api_client.dart';
import '../models/news_item.dart';

class NewsService {
  NewsService(this._apiClient);

  final ApiClient _apiClient;

  static const String newsEndpoint = '/news';
  static String newsByIdEndpoint(String id) => '/news/$id';

  List<NewsItem> _cachedNews = [];

  /// Endpoint: GET /news
  Future<List<NewsItem>> getNews() async {
    final response = await _apiClient.getJsonFlexible(newsEndpoint);
    final items = _extractList(response);
    final newsItems = items
        .whereType<Map<String, dynamic>>()
        .map(NewsItem.fromJson)
        .toList();
    _cachedNews = newsItems;
    return newsItems;
  }

  /// Endpoint: POST /news
  Future<NewsItem> createNews({
    required String title,
    required String category,
    required String body,
  }) async {
    final payload = _buildPayload(title, category, body);
    final data = await _apiClient.postJson(newsEndpoint, payload);
    final item = NewsItem.fromJson(data);
    _cachedNews = [item, ..._cachedNews];
    return item;
  }

  /// Endpoint: PUT /news/:id
  Future<NewsItem> updateNews({
    required String id,
    required String title,
    required String category,
    required String body,
  }) async {
    final payload = _buildPayload(title, category, body);
    final data = await _apiClient.putJson(newsByIdEndpoint(id), payload);
    final updated = NewsItem.fromJson(data);
    _cachedNews = _cachedNews
        .map((item) => item.id == id ? updated : item)
        .toList();
    return updated;
  }

  /// Endpoint: DELETE /news/:id
  Future<void> deleteNews(String id) async {
    await _apiClient.deleteJson(newsByIdEndpoint(id));
    _cachedNews = _cachedNews.where((item) => item.id != id).toList();
  }

  List<String> get availableCategories {
    final categories = _cachedNews.map((item) => item.category).toSet();
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

  Map<String, dynamic> _buildPayload(
    String title,
    String category,
    String body,
  ) {
    return {
      'title': title.trim(),
      'category': category.trim(),
      'body': body.trim(),
      'excerpt': _createExcerpt(body),
    };
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List<dynamic>) {
      return response;
    }
    if (response is Map<String, dynamic>) {
      final data = response['data'] ?? response['news'];
      if (data is List<dynamic>) {
        return data;
      }
    }
    return const <dynamic>[];
  }

  String _createExcerpt(String body) {
    final trimmed = body.trim();
    if (trimmed.length <= 120) {
      return trimmed;
    }
    return '${trimmed.substring(0, 117)}...';
  }
}
