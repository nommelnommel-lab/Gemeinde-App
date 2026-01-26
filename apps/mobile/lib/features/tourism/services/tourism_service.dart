import '../../../api/api_client.dart';
import '../models/tourism_item.dart';

class TourismService {
  TourismService(this._apiClient);

  final ApiClient _apiClient;

  static const String tourismEndpoint = '/api/tourism';

  Future<List<TourismItem>> getItems({
    required TourismItemType type,
    int? limit,
    int? offset,
    String? query,
  }) async {
    final params = <String, String>{
      'type': type.apiValue,
      if (limit != null) 'limit': '$limit',
      if (offset != null) 'offset': '$offset',
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
    };
    final uri = _buildQuery(tourismEndpoint, params);
    final response = await _apiClient.getJsonFlexible(uri);
    final items = _extractList(response);
    return items
        .whereType<Map<String, dynamic>>()
        .map(TourismItem.fromJson)
        .toList();
  }

  Future<TourismItem> getItem(String id) async {
    final response = await _apiClient.getJsonFlexible('$tourismEndpoint/$id');
    final data = _extractMap(response);
    return TourismItem.fromJson(data);
  }

  String _buildQuery(String path, Map<String, String> params) {
    if (params.isEmpty) return path;
    final query = params.entries
        .map((entry) => '${entry.key}=${Uri.encodeQueryComponent(entry.value)}')
        .join('&');
    return '$path?$query';
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List<dynamic>) {
      return response;
    }
    if (response is Map<String, dynamic>) {
      final data = response['data'] ?? response['items'];
      if (data is List<dynamic>) {
        return data;
      }
    }
    return const <dynamic>[];
  }

  Map<String, dynamic> _extractMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }
    return const <String, dynamic>{};
  }
}
