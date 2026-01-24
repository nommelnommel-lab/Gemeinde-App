class TenantBranding {
  const TenantBranding({
    this.logoUrl,
    this.primaryColor,
    this.secondaryColor,
  });

  final String? logoUrl;
  final String? primaryColor;
  final String? secondaryColor;

  factory TenantBranding.fromJson(dynamic value) {
    if (value is Map<String, dynamic>) {
      return TenantBranding(
        logoUrl: value['logoUrl'] as String? ?? value['logo'] as String?,
        primaryColor: _readColor(value['primaryColor'] ?? value['primary_color']),
        secondaryColor:
            _readColor(value['secondaryColor'] ?? value['secondary_color']),
      );
    }
    return const TenantBranding();
  }

  Map<String, dynamic> toJson() => {
        'logoUrl': logoUrl,
        'primaryColor': primaryColor,
        'secondaryColor': secondaryColor,
      };

  static String? _readColor(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }
}

class OpeningHoursEntry {
  const OpeningHoursEntry({required this.day, required this.hours});

  final String day;
  final List<String> hours;

  factory OpeningHoursEntry.fromJson(Map<String, dynamic> json) {
    final hours = <String>[];
    final list = json['hours'] ?? json['times'];
    if (list is List<dynamic>) {
      hours.addAll(list.whereType<String>());
    }
    final from = json['from'];
    final to = json['to'];
    if (from is String && to is String) {
      hours.add('${from.trim()} - ${to.trim()}');
    }
    final single = json['time'];
    if (single is String && single.trim().isNotEmpty) {
      hours.add(single.trim());
    }

    return OpeningHoursEntry(
      day: json['day'] as String? ?? json['weekday'] as String? ?? '',
      hours: hours,
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'hours': hours,
      };
}

class TenantSettings {
  const TenantSettings({
    required this.name,
    required this.address,
    required this.openingHours,
    required this.featureFlags,
    required this.branding,
    this.contactPhone,
    this.contactEmail,
    this.websiteUrl,
  });

  final String name;
  final String address;
  final String? contactPhone;
  final String? contactEmail;
  final String? websiteUrl;
  final List<OpeningHoursEntry> openingHours;
  final Map<String, bool> featureFlags;
  final TenantBranding branding;

  factory TenantSettings.fromJson(Map<String, dynamic> json) {
    final openingHours = _parseList(json, const [
      'openingHoursJson',
      'openingHours',
      'opening_hours',
      'hours',
      'openingTimes',
    ]);
    final featureFlags = _parseMap(json, const [
      'featureFlagsJson',
      'featureFlags',
      'features',
    ]);

    return TenantSettings(
      name: _readString(json, const ['name', 'gemeindeName', 'tenantName']),
      address: _parseAddress(json['address'] ?? json['adresse']),
      contactPhone:
          _readOptionalString(json, const ['contactPhone', 'phone', 'telefon', 'tel']),
      contactEmail:
          _readOptionalString(json, const ['contactEmail', 'email', 'mail']),
      websiteUrl:
          _readOptionalString(json, const ['websiteUrl', 'website', 'web']),
      openingHours: openingHours
          .whereType<Map<String, dynamic>>()
          .map(OpeningHoursEntry.fromJson)
          .toList(),
      featureFlags: featureFlags,
      branding: TenantBranding.fromJson(
        json['brandingJson'] ?? json['branding'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'contactPhone': contactPhone,
        'contactEmail': contactEmail,
        'websiteUrl': websiteUrl,
        'openingHoursJson': openingHours.map((entry) => entry.toJson()).toList(),
        'featureFlagsJson': featureFlags,
        'brandingJson': branding.toJson(),
      };

  bool isFeatureEnabled(String key) => featureFlags[key] ?? true;

  static List<dynamic> _parseList(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is List<dynamic>) {
        return value;
      }
    }
    return const [];
  }

  static Map<String, bool> _parseMap(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return value.map((mapKey, mapValue) {
          final boolValue = mapValue is bool
              ? mapValue
              : mapValue is String
                  ? mapValue.toLowerCase() == 'true'
                  : false;
          return MapEntry(mapKey, boolValue);
        });
      }
    }
    return const {};
  }

  static String _parseAddress(dynamic value) {
    if (value is String) {
      return value;
    }
    if (value is Map<String, dynamic>) {
      final street = value['street'] ?? value['line1'] ?? value['address1'];
      final zip = value['zip'] ?? value['postalCode'];
      final city = value['city'] ?? value['town'];
      final parts = [
        if (street is String && street.trim().isNotEmpty) street,
        if (zip is String && zip.trim().isNotEmpty && city is String)
          '${zip.trim()} ${city.trim()}'.trim(),
        if (city is String && city.trim().isNotEmpty && zip is! String)
          city.trim(),
      ];
      return parts.join('\n');
    }
    return '';
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String) {
        return value;
      }
    }
    return '';
  }

  static String? _readOptionalString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}
