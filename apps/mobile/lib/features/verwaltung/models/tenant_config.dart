class TenantConfig {
  const TenantConfig({
    required this.name,
    required this.address,
    required this.openingHours,
    required this.emergencyNumbers,
    this.phone,
    this.email,
    this.website,
  });

  final String name;
  final String address;
  final String? phone;
  final String? email;
  final String? website;
  final List<OpeningHoursEntry> openingHours;
  final List<EmergencyNumber> emergencyNumbers;

  factory TenantConfig.fromJson(Map<String, dynamic> json) {
    final openingHours = _parseList(json, const [
      'openingHours',
      'opening_hours',
      'hours',
      'openingTimes',
    ]);
    final emergencyNumbers = _parseList(json, const [
      'emergencyNumbers',
      'emergency_numbers',
      'emergencyContacts',
    ]);

    return TenantConfig(
      name: _readString(json, const ['name', 'gemeindeName', 'tenantName']),
      address: _parseAddress(json['address'] ?? json['adresse']),
      phone: _readOptionalString(json, const ['phone', 'telefon', 'tel']),
      email: _readOptionalString(json, const ['email', 'mail']),
      website: _readOptionalString(json, const ['website', 'web']),
      openingHours: openingHours
          .whereType<Map<String, dynamic>>()
          .map(OpeningHoursEntry.fromJson)
          .toList(),
      emergencyNumbers: emergencyNumbers
          .whereType<Map<String, dynamic>>()
          .map(EmergencyNumber.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'phone': phone,
        'email': email,
        'website': website,
        'openingHours': openingHours.map((entry) => entry.toJson()).toList(),
        'emergencyNumbers':
            emergencyNumbers.map((entry) => entry.toJson()).toList(),
      };

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

class EmergencyNumber {
  const EmergencyNumber({required this.label, required this.number});

  final String label;
  final String number;

  factory EmergencyNumber.fromJson(Map<String, dynamic> json) {
    return EmergencyNumber(
      label: json['label'] as String? ?? json['title'] as String? ?? '',
      number: json['number'] as String? ?? json['phone'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'number': number,
      };
}
