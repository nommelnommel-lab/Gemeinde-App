import 'package:flutter/foundation.dart';

enum PostCategory {
  flohmarkt,
  cafeTreff,
  seniorenHilfe,
  umzugEntruempelung,
  kinderSpielen,
}

extension PostCategoryDetails on PostCategory {
  String get slug {
    switch (this) {
      case PostCategory.flohmarkt:
        return 'flohmarkt';
      case PostCategory.cafeTreff:
        return 'cafe_treff';
      case PostCategory.seniorenHilfe:
        return 'senioren_hilfe';
      case PostCategory.umzugEntruempelung:
        return 'umzug_entruempelung';
      case PostCategory.kinderSpielen:
        return 'kinderspielen';
    }
  }

  String get label {
    switch (this) {
      case PostCategory.flohmarkt:
        return 'Flohmarkt';
      case PostCategory.cafeTreff:
        return 'Café Treff';
      case PostCategory.seniorenHilfe:
        return 'Senioren Hilfe';
      case PostCategory.umzugEntruempelung:
        return 'Umzug / Entrümpelung';
      case PostCategory.kinderSpielen:
        return 'Kinderspielen';
    }
  }

  static PostCategory? fromSlug(String value) {
    for (final category in PostCategory.values) {
      if (category.slug == value) {
        return category;
      }
    }
    return null;
  }
}

@immutable
class Post {
  const Post({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final PostCategory category;
  final String title;
  final String body;
  final DateTime createdAt;

  Post copyWith({
    String? title,
    String? body,
  }) {
    return Post(
      id: id,
      category: category,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt,
    );
  }
}

@immutable
class PostInput {
  const PostInput({required this.title, required this.body});

  final String title;
  final String body;
}
