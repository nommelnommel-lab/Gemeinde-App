import '../../../api/api_client.dart';
import '../models/citizen_post.dart';

class CitizenPostsService {
  CitizenPostsService(this._apiClient);

  final ApiClient _apiClient;

  static const String postsEndpoint = '/posts';
  static String postByIdEndpoint(String id) => '/posts/$id';
  static String reportPostEndpoint(String id) => '/posts/$id/report';

  Future<List<CitizenPost>> getPosts({required CitizenPostType type}) async {
    final response = await _apiClient.getJsonFlexible(
      '${postsEndpoint}?type=${type.apiValue}',
      includeAuth: true,
    );
    final payload = _extractList(response);
    return payload
        .whereType<Map<String, dynamic>>()
        .map(CitizenPost.fromJson)
        .toList();
  }

  Future<CitizenPost> createPost(CitizenPostInput input) async {
    final data = await _apiClient.postJson(
      postsEndpoint,
      input.toJson(),
      includeAuth: true,
    );
    final payload = _extractMap(data);
    return CitizenPost.fromJson(payload);
  }

  Future<void> deletePost(String id) async {
    await _apiClient.deleteJson(
      postByIdEndpoint(id),
      includeAuth: true,
    );
  }

  Future<void> reportPost(String id) async {
    await _apiClient.postJson(
      reportPostEndpoint(id),
      const {},
      includeAuth: true,
    );
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List<dynamic>) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      final nested = data['data'] ?? data['posts'];
      if (nested is List<dynamic>) {
        return nested;
      }
    }
    return const <dynamic>[];
  }

  Map<String, dynamic> _extractMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'] ?? data['post'];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
      return data;
    }
    return const <String, dynamic>{};
  }
}
