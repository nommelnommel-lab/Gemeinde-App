import '../../../api/api_client.dart';
import '../models/verwaltung_item.dart';

class VerwaltungService {
  VerwaltungService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<VerwaltungItem>> getItems({
    required VerwaltungItemKind kind,
    String? category,
    String? query,
  }) async {
    final params = <String, String>{
      'kind': kind.apiValue,
    };
    if (category != null && category.trim().isNotEmpty) {
      params['category'] = category.trim();
    }
    if (query != null && query.trim().isNotEmpty) {
      params['q'] = query.trim();
    }

    final uri = Uri(
      path: '/api/verwaltung/items',
      queryParameters: params.isEmpty ? null : params,
    );
    final data = await _apiClient.getJsonList(uri.toString());
    final items = data
        .whereType<Map<String, dynamic>>()
        .map(VerwaltungItem.fromJson)
        .toList();
    items.sort((a, b) {
      if (a.sortOrder != b.sortOrder) {
        return a.sortOrder.compareTo(b.sortOrder);
      }
      return a.title.compareTo(b.title);
    });
    return items;
  }
}
