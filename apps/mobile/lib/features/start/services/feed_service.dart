import '../../../api/api_client.dart';
import '../../events/models/event.dart';
import '../../news/models/news_item.dart';
import '../../warnings/models/warning_item.dart';

class FeedSnapshot {
  const FeedSnapshot({
    required this.events,
    required this.news,
    required this.warnings,
  });

  final List<Event> events;
  final List<NewsItem> news;
  final List<WarningItem> warnings;
}

class FeedService {
  FeedService(this._apiClient);

  final ApiClient _apiClient;

  Future<FeedSnapshot> getFeed() async {
    final response = await _apiClient.getJsonFlexible('/api/feed');
    final payload =
        response is Map<String, dynamic> ? response : <String, dynamic>{};

    final events = _extractList(payload['events'])
        .whereType<Map<String, dynamic>>()
        .map(_mapFeedEvent)
        .toList();

    final posts = _extractList(payload['posts']).whereType<Map<String, dynamic>>();
    final news = <NewsItem>[];
    final warnings = <WarningItem>[];

    for (final post in posts) {
      final type = (post['type'] ?? '').toString();
      if (type.toUpperCase() == 'WARNING') {
        warnings.add(_mapWarning(post));
      } else {
        news.add(_mapNews(post));
      }
    }

    return FeedSnapshot(events: events, news: news, warnings: warnings);
  }

  List<dynamic> _extractList(dynamic value) {
    if (value is List<dynamic>) {
      return value;
    }
    return const <dynamic>[];
  }

  Event _mapFeedEvent(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    normalized['date'] ??= json['startAt'] ?? json['start_at'];
    normalized['createdAt'] ??= json['created_at'] ?? normalized['date'];
    normalized['updatedAt'] ??= json['updated_at'] ?? normalized['date'];
    return Event.fromJson(normalized);
  }

  NewsItem _mapNews(Map<String, dynamic> json) {
    final body = (json['body'] ?? '').toString();
    final excerpt = (json['excerpt'] ?? _createExcerpt(body)).toString();
    return NewsItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      excerpt: excerpt,
      body: body,
      publishedAt: _parseDate(json['publishedAt'] ?? json['createdAt']),
      category: (json['category'] ?? 'Allgemein').toString(),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  WarningItem _mapWarning(Map<String, dynamic> json) {
    return WarningItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      severity: _mapSeverity(json['priority'] ?? json['severity']),
      publishedAt: _parseDate(json['publishedAt'] ?? json['createdAt']),
      validUntil: _parseOptionalDate(json['endsAt'] ?? json['validUntil']),
      source: json['source'] as String?,
    );
  }

  WarningSeverity _mapSeverity(dynamic value) {
    final normalized = value?.toString().toUpperCase();
    switch (normalized) {
      case 'HIGH':
      case 'CRITICAL':
        return WarningSeverity.critical;
      case 'MEDIUM':
      case 'WARNING':
        return WarningSeverity.warning;
      case 'LOW':
      case 'INFO':
      default:
        return WarningSeverity.info;
    }
  }

  DateTime _parseDate(dynamic value) {
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

  DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) {
      return null;
    }
    return _parseDate(value);
  }

  String _createExcerpt(String body) {
    final trimmed = body.trim();
    if (trimmed.length <= 120) {
      return trimmed;
    }
    return '${trimmed.substring(0, 117)}...';
  }
}
