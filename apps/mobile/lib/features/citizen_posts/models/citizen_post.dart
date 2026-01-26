import 'package:flutter/foundation.dart';

enum CitizenPostType {
  marketplace,
  movingClearance,
  help,
  cafeMeetup,
  kidsMeetup,
  apartmentSearch,
  lostFound,
  rideSharing,
  jobsLocal,
  volunteering,
  giveaway,
  skillExchange,
}

extension CitizenPostTypeDetails on CitizenPostType {
  String get apiValue {
    switch (this) {
      case CitizenPostType.marketplace:
        return 'marketplace';
      case CitizenPostType.movingClearance:
        return 'moving_clearance';
      case CitizenPostType.help:
        return 'help';
      case CitizenPostType.cafeMeetup:
        return 'cafe_meetup';
      case CitizenPostType.kidsMeetup:
        return 'kids_meetup';
      case CitizenPostType.apartmentSearch:
        return 'apartment_search';
      case CitizenPostType.lostFound:
        return 'lost_found';
      case CitizenPostType.rideSharing:
        return 'ride_sharing';
      case CitizenPostType.jobsLocal:
        return 'jobs_local';
      case CitizenPostType.volunteering:
        return 'volunteering';
      case CitizenPostType.giveaway:
        return 'giveaway';
      case CitizenPostType.skillExchange:
        return 'skill_exchange';
    }
  }

  String get label {
    switch (this) {
      case CitizenPostType.marketplace:
        return 'Online Flohmarkt';
      case CitizenPostType.movingClearance:
        return 'Umzug/Entrümpelung';
      case CitizenPostType.help:
        return 'Senioren Hilfe';
      case CitizenPostType.cafeMeetup:
        return 'Café Treff';
      case CitizenPostType.kidsMeetup:
        return 'Kinderspielen';
      case CitizenPostType.apartmentSearch:
        return 'Wohnungssuche';
      case CitizenPostType.lostFound:
        return 'Fundbüro';
      case CitizenPostType.rideSharing:
        return 'Mitfahrgelegenheit';
      case CitizenPostType.jobsLocal:
        return 'Lokale Jobs';
      case CitizenPostType.volunteering:
        return 'Ehrenamt';
      case CitizenPostType.giveaway:
        return 'Verschenken';
      case CitizenPostType.skillExchange:
        return 'Skill-Tausch';
    }
  }

  static CitizenPostType? fromValue(String? value) {
    if (value == null) return null;
    final normalized = value.toLowerCase();
    switch (normalized) {
      case 'marketplace_listing':
      case 'marketplace':
        return CitizenPostType.marketplace;
      case 'moving_clearance':
      case 'moving':
        return CitizenPostType.movingClearance;
      case 'help_request':
      case 'help_offer':
      case 'help':
        return CitizenPostType.help;
      case 'cafe_meetup':
      case 'cafe':
        return CitizenPostType.cafeMeetup;
      case 'kids_meetup':
      case 'kids':
        return CitizenPostType.kidsMeetup;
      case 'apartment_search':
      case 'apartment':
        return CitizenPostType.apartmentSearch;
      case 'lost_found':
      case 'lost':
      case 'found':
        return CitizenPostType.lostFound;
      case 'ride_sharing':
        return CitizenPostType.rideSharing;
      case 'jobs_local':
        return CitizenPostType.jobsLocal;
      case 'volunteering':
        return CitizenPostType.volunteering;
      case 'giveaway':
        return CitizenPostType.giveaway;
      case 'skill_exchange':
        return CitizenPostType.skillExchange;
    }
    return null;
  }
}

@immutable
class CitizenPost {
  const CitizenPost({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.authorUserId,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final CitizenPostType type;
  final String title;
  final String body;
  final String? authorUserId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CitizenPost.fromJson(Map<String, dynamic> json) {
    final typeValue = CitizenPostTypeDetails.fromValue(
      json['type']?.toString(),
    );
    final createdAtValue = json['createdAt'] ?? json['created_at'];
    final updatedAtValue = json['updatedAt'] ?? json['updated_at'];
    final authorUserId = json['authorUserId'] ??
        json['authorId'] ??
        json['author_user_id'] ??
        json['author_userId'];
    return CitizenPost(
      id: (json['id'] ?? '').toString(),
      type: typeValue ?? CitizenPostType.marketplace,
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      authorUserId: json['authorUserId']?.toString() ??
          json['authorId']?.toString() ??
          json['userId']?.toString() ??
          json['createdBy']?.toString(),
      metadata: _parseMetadata(json['metadata']),
      createdAt: _parseDate(createdAtValue) ?? DateTime.now(),
      updatedAt: _parseDate(updatedAtValue) ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> _parseMetadata(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map(
          (entry) => MapEntry(
            entry.key.toString(),
            entry.value,
          ),
        ),
      );
    }
    return const <String, dynamic>{};
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
class CitizenPostInput {
  const CitizenPostInput({
    required this.type,
    required this.title,
    required this.body,
    required this.metadata,
  });

  final CitizenPostType type;
  final String title;
  final String body;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return {
      'type': type.apiValue,
      'title': title.trim(),
      'body': body.trim(),
      'metadata': metadata,
    };
  }
}
