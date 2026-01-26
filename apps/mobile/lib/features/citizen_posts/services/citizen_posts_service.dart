import '../../../api/api_client.dart';
import '../models/citizen_post.dart';

class CitizenPostsService {
  CitizenPostsService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<CitizenPost>> getPosts({
    required CitizenPostType type,
    String? query,
  }) async {
    final response = await _apiClient.fetchPosts(
      type: type.apiValue,
      query: query,
    );
    final payload = _extractList(response);
    final posts = payload
        .whereType<Map<String, dynamic>>()
        .map(CitizenPost.fromJson)
        .toList();
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  Future<List<CitizenPost>> getPostsForTypes({
    required List<CitizenPostType> types,
    String? query,
  }) async {
    if (types.isEmpty) {
      return const [];
    }
    if (types.length == 1) {
      return getPosts(type: types.first, query: query);
    }
    final uniqueTypes = types.toSet().toList();
    final results = await Future.wait(
      uniqueTypes.map(
        (type) => getPosts(type: type, query: query),
      ),
    );
    final merged = <String, CitizenPost>{};
    for (final batch in results) {
      for (final post in batch) {
        merged[post.id] = post;
      }
    }
    final posts = merged.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  Future<CitizenPost> createPost(CitizenPostInput input) async {
    final data = await _apiClient.createPost(input.toJson());
    final payload = _extractMap(data);
    return CitizenPost.fromJson(payload);
  }

  Future<CitizenPost> updatePost(
    String id,
    CitizenPostInput input,
  ) async {
    final data = await _apiClient.updatePost(id, input.toJson());
    final payload = _extractMap(data);
    return CitizenPost.fromJson(payload);
  }

  Future<void> deletePost(String id) async {
    await _apiClient.deletePost(id);
  }

  Future<void> reportPost(String id) async {
    await _apiClient.reportPost(id);
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
