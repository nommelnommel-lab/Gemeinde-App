enum TourismItemType {
  hikingRoute,
  sight,
  leisure,
  restaurant,
}

extension TourismItemTypeLabel on TourismItemType {
  String get apiValue {
    switch (this) {
      case TourismItemType.hikingRoute:
        return 'HIKING_ROUTE';
      case TourismItemType.sight:
        return 'SIGHT';
      case TourismItemType.leisure:
        return 'LEISURE';
      case TourismItemType.restaurant:
        return 'RESTAURANT';
    }
  }

  String get label {
    switch (this) {
      case TourismItemType.hikingRoute:
        return 'Wanderrouten';
      case TourismItemType.sight:
        return 'Sehenswürdigkeiten';
      case TourismItemType.leisure:
        return 'Freizeitangebote';
      case TourismItemType.restaurant:
        return 'Restaurants';
    }
  }
}

class TourismItem {
  const TourismItem({
    required this.id,
    required this.tenantId,
    required this.type,
    required this.title,
    required this.body,
    required this.metadata,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String tenantId;
  final TourismItemType type;
  final String title;
  final String body;
  final Map<String, dynamic> metadata;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TourismItem.fromJson(Map<String, dynamic> json) {
    return TourismItem(
      id: json['id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      type: _parseType(json['type']),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const {},
      ),
      status: json['status'] as String? ?? 'PUBLISHED',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String? metadataString(String key) {
    final value = metadata[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static TourismItemType _parseType(dynamic value) {
    final normalized = value?.toString().toUpperCase();
    switch (normalized) {
      case 'HIKING_ROUTE':
        return TourismItemType.hikingRoute;
      case 'SIGHT':
        return TourismItemType.sight;
      case 'LEISURE':
        return TourismItemType.leisure;
      case 'RESTAURANT':
        return TourismItemType.restaurant;
      default:
        return TourismItemType.sight;
    }
  }
}
