import 'dart:math';

import '../models/post.dart';

class PostsService {
  factory PostsService() => _instance;

  PostsService._internal() {
    if (_postsByCategory.isEmpty) {
      _seedPosts();
    }
  }

  static final PostsService _instance = PostsService._internal();
  final Map<PostCategory, List<Post>> _postsByCategory = {};

  Future<List<Post>> getPosts(PostCategory category) async {
    final posts = List<Post>.from(_postsByCategory[category] ?? const []);
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List<Post>.unmodifiable(posts);
  }

  Future<Post> createPost(PostCategory category, PostInput input) async {
    final post = Post(
      id: _generateId(),
      category: category,
      title: input.title,
      body: input.body,
      createdAt: DateTime.now(),
    );
    final list = _postsByCategory.putIfAbsent(category, () => []);
    list.add(post);
    return post;
  }

  Future<Post> updatePost(String id, PostInput input) async {
    for (final entry in _postsByCategory.entries) {
      final index = entry.value.indexWhere((post) => post.id == id);
      if (index != -1) {
        final updated = entry.value[index].copyWith(
          title: input.title,
          body: input.body,
        );
        entry.value[index] = updated;
        return updated;
      }
    }
    throw StateError('Post nicht gefunden');
  }

  void _seedPosts() {
    final now = DateTime.now();
    _postsByCategory[PostCategory.flohmarkt] = [
      Post(
        id: _generateId(),
        category: PostCategory.flohmarkt,
        title: 'Kinderfahrrad zu verkaufen',
        body: 'Gepflegtes 16-Zoll-Rad, Abholung in der Lindenstraße.',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Post(
        id: _generateId(),
        category: PostCategory.flohmarkt,
        title: 'Flohmarktstand teilen',
        body: 'Suche Mitstreiter für den Hofflohmarkt am Samstag.',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];
    _postsByCategory[PostCategory.cafeTreff] = [
      Post(
        id: _generateId(),
        category: PostCategory.cafeTreff,
        title: 'Kaffeerunde am Mittwoch',
        body: 'Treffen um 15 Uhr im Gemeindezentrum. Kuchen bitte mitbringen.',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Post(
        id: _generateId(),
        category: PostCategory.cafeTreff,
        title: 'Neue Nachbarn willkommen',
        body: 'Samstagsfrühstück im Café am Markt – alle sind eingeladen.',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];
    _postsByCategory[PostCategory.seniorenHilfe] = [
      Post(
        id: _generateId(),
        category: PostCategory.seniorenHilfe,
        title: 'Fahrdienst zum Arzt gesucht',
        body: 'Wer kann mich nächste Woche Dienstag zum Arzt begleiten?',
        createdAt: now.subtract(const Duration(days: 1, hours: 5)),
      ),
      Post(
        id: _generateId(),
        category: PostCategory.seniorenHilfe,
        title: 'Telefonpatenschaft',
        body: 'Ich rufe gern einmal pro Woche an. Bitte melden!',
        createdAt: now.subtract(const Duration(days: 4)),
      ),
    ];
    _postsByCategory[PostCategory.umzugEntruempelung] = [
      Post(
        id: _generateId(),
        category: PostCategory.umzugEntruempelung,
        title: 'Helfer für Umzug gesucht',
        body: 'Brauche zwei kräftige Hände für Samstagvormittag.',
        createdAt: now.subtract(const Duration(days: 2, hours: 3)),
      ),
      Post(
        id: _generateId(),
        category: PostCategory.umzugEntruempelung,
        title: 'Keller entrümpeln',
        body: 'Suche Unterstützung beim Ausräumen. Werkzeug vorhanden.',
        createdAt: now.subtract(const Duration(days: 6)),
      ),
    ];
    _postsByCategory[PostCategory.kinderSpielen] = [
      Post(
        id: _generateId(),
        category: PostCategory.kinderSpielen,
        title: 'Spielplatz-Treff',
        body: 'Freitag 16 Uhr am See-Spielplatz, Snacks willkommen.',
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      Post(
        id: _generateId(),
        category: PostCategory.kinderSpielen,
        title: 'Eltern-Kind-Spielgruppe',
        body: 'Neue Runde im Gemeindehaus, montags um 10 Uhr.',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  String _generateId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = Random().nextInt(1000);
    return 'post_$timestamp$random';
  }
}
