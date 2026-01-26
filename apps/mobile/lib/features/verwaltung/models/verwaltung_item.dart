enum VerwaltungItemKind {
  form,
  link,
}

extension VerwaltungItemKindLabel on VerwaltungItemKind {
  String get label {
    switch (this) {
      case VerwaltungItemKind.form:
        return 'Formulare';
      case VerwaltungItemKind.link:
        return 'Wichtige Links';
    }
  }

  String get apiValue {
    switch (this) {
      case VerwaltungItemKind.form:
        return 'FORM';
      case VerwaltungItemKind.link:
        return 'LINK';
    }
  }
}

class VerwaltungItem {
  const VerwaltungItem({
    required this.id,
    required this.kind,
    required this.category,
    required this.title,
    required this.description,
    required this.url,
    required this.tags,
    required this.sortOrder,
  });

  final String id;
  final VerwaltungItemKind kind;
  final String category;
  final String title;
  final String description;
  final String url;
  final List<String> tags;
  final int sortOrder;

  factory VerwaltungItem.fromJson(Map<String, dynamic> json) {
    return VerwaltungItem(
      id: json['id'] as String? ?? '',
      kind: _parseKind(json['kind'] as String?),
      category: json['category'] as String? ?? 'Allgemein',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      url: json['url'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  static VerwaltungItemKind _parseKind(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'LINK':
        return VerwaltungItemKind.link;
      case 'FORM':
      default:
        return VerwaltungItemKind.form;
    }
  }
}
