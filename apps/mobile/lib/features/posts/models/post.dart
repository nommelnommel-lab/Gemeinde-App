import 'package:flutter/foundation.dart';

enum PostType {
  event,
  news,
  warning,
}

extension PostTypeDetails on PostType {
  String get apiValue {
    switch (this) {
      case PostType.event:
        return 'event';
      case PostType.news:
        return 'news';
      case PostType.warning:
        return 'warning';
    }
  }

  String get label {
    switch (this) {
      case PostType.event:
        return 'Event';
      case PostType.news:
        return 'News';
      case PostType.warning:
        return 'Warnung';
    }
  }

  static PostType? fromValue(String? value) {
    if (value == null) return null;
    final normalized = value.toLowerCase();
    for (final type in PostType.values) {
      if (type.apiValue == normalized) {
        return type;
      }
    }
    return null;
  }
}

@immutable
class Post {
  const Post({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.date,
    this.location,
    this.severity,
    this.validUntil,
  });

  final String id;
  final PostType type;
  final String title;
  final String body;
  final DateTime? date;
  final String? location;
  final String? severity;
  final DateTime? validUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Post.fromJson(Map<String, dynamic> json) {
    final type = PostTypeDetails.fromValue(json['type']?.toString()) ??
        PostType.news;
    final createdAtValue = json['createdAt'] ?? json['created_at'];
    final updatedAtValue = json['updatedAt'] ?? json['updated_at'];

    return Post(
      id: (json['id'] ?? '').toString(),
      type: type,
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      date: _parseDate(json['date']),
      location: json['location']?.toString(),
      severity: json['severity']?.toString(),
      validUntil: _parseDate(json['validUntil'] ?? json['valid_until']),
      createdAt: _parseDate(createdAtValue) ?? DateTime.now(),
      updatedAt: _parseDate(updatedAtValue) ?? DateTime.now(),
    );
  }

  Post copyWith({
    String? title,
    String? body,
    DateTime? date,
    String? location,
    String? severity,
    DateTime? validUntil,
  }) {
    return Post(
      id: id,
      type: type,
      title: title ?? this.title,
      body: body ?? this.body,
      date: date ?? this.date,
      location: location ?? this.location,
      severity: severity ?? this.severity,
      validUntil: validUntil ?? this.validUntil,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.tryParse(value.toString());
  }
}

@immutable
class PostInput {
  const PostInput({
    required this.type,
    required this.title,
    required this.body,
    this.date,
    this.location,
    this.severity,
    this.validUntil,
  });

  final PostType type;
  final String title;
  final String body;
  final DateTime? date;
  final String? location;
  final String? severity;
  final DateTime? validUntil;

  Map<String, dynamic> toJson() {
    return {
      'type': type.apiValue,
      'title': title.trim(),
      'body': body.trim(),
      if (date != null) 'date': date!.toIso8601String(),
      if (location != null) 'location': location,
      if (severity != null) 'severity': severity,
      if (validUntil != null) 'validUntil': validUntil!.toIso8601String(),
    };
  }
}
