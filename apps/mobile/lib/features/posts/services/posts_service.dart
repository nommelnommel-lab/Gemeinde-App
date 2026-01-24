import '../../../api/api_client.dart';
import '../models/post.dart';

class PostsService {
  PostsService(this._apiClient);

  final ApiClient _apiClient;

  static const String postsEndpoint = '/posts';
  static String postByIdEndpoint(String id) => '/posts/$id';

  /// Endpoint: GET /posts
  Future<List<Post>> getPosts({PostType? type}) async {
    final path = type == null
        ? postsEndpoint
        : '$postsEndpoint?type=${type.apiValue}';
    final response = await _apiClient.getJsonFlexible(path);
    final items = _extractList(response);
    return items
        .whereType<Map<String, dynamic>>()
        .map(Post.fromJson)
        .toList();
  }

  /// Endpoint: GET /posts/:id
  Future<Post> getPost(String id) async {
    final response = await _apiClient.getJsonFlexible(postByIdEndpoint(id));
    final data = _extractMap(response);
    return Post.fromJson(data);
  }

  /// Endpoint: POST /posts
  Future<Post> createPost(
    PostInput input, {
    bool canEdit = false,
  }) async {
    _assertPermission(canEdit);
    final data = await _apiClient.postJson(postsEndpoint, input.toJson());
    return Post.fromJson(data);
  }

  /// Endpoint: PUT /posts/:id
  Future<Post> updatePost(
    String id,
    PostInput input, {
    bool canEdit = false,
  }) async {
    _assertPermission(canEdit);
    final data = await _apiClient.putJson(
      postByIdEndpoint(id),
      input.toJson(),
    );
    return Post.fromJson(data);
  }

  /// Endpoint: DELETE /posts/:id
  Future<void> deletePost(
    String id, {
    bool canEdit = false,
  }) async {
    _assertPermission(canEdit);
    await _apiClient.deleteJson(postByIdEndpoint(id));
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List<dynamic>) {
      return response;
    }
    if (response is Map<String, dynamic>) {
      final data = response['data'] ?? response['posts'];
      if (data is List<dynamic>) {
        return data;
      }
    }
    return const <dynamic>[];
  }

  Map<String, dynamic> _extractMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'] ?? response['post'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return response;
    }
    throw ApiException('Unerwartetes JSON-Format');
  }

  void _assertPermission(bool canEdit) {
    if (!canEdit) {
      throw StateError('Keine Berechtigung für diese Aktion.');
    }
  }
}
