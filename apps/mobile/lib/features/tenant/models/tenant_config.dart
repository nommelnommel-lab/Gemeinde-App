class TenantConfig {
  const TenantConfig({
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.website,
    required this.openingHours,
    required this.emergencyNumbers,
  });

  final String name;
  final String address;
  final String phone;
  final String email;
  final String website;
  final List<TenantOpeningHour> openingHours;
  final List<String> emergencyNumbers;

  factory TenantConfig.empty() {
    return const TenantConfig(
      name: '',
      address: '',
      phone: '',
      email: '',
      website: '',
      openingHours: [],
      emergencyNumbers: [],
    );
  }

  factory TenantConfig.fromJson(Map<String, dynamic> json) {
    final openingHoursRaw = _readList(json, [
      'openingHours',
      'opening_hours',
      'hours',
    ]);
    final emergencyRaw = _readList(json, [
      'emergencyNumbers',
      'emergency_numbers',
      'emergency',
    ]);

    return TenantConfig(
      name: _readString(json, ['name', 'title']),
      address: _readString(json, ['address', 'location']),
      phone: _readString(json, ['phone', 'phoneNumber']),
      email: _readString(json, ['email', 'mail']),
      website: _readString(json, ['website', 'url']),
      openingHours: openingHoursRaw
              ?.whereType<Map<String, dynamic>>()
              .map(TenantOpeningHour.fromJson)
              .toList() ??
          const [],
      emergencyNumbers: emergencyRaw
              ?.map((value) => _readEmergencyNumber(value))
              .whereType<String>()
              .toList() ??
          const [],
    );
  }

  TenantConfig copyWith({
    String? name,
    String? address,
    String? phone,
    String? email,
    String? website,
    List<TenantOpeningHour>? openingHours,
    List<String>? emergencyNumbers,
  }) {
    return TenantConfig(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      openingHours: openingHours ?? this.openingHours,
      emergencyNumbers: emergencyNumbers ?? this.emergencyNumbers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      'address': address.trim(),
      'phone': phone.trim(),
      'email': email.trim(),
      'website': website.trim(),
      'openingHours': openingHours.map((entry) => entry.toJson()).toList(),
      'emergencyNumbers':
          emergencyNumbers.map((entry) => entry.trim()).toList(),
    };
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

  static List<dynamic>? _readList(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is List<dynamic>) {
        return value;
      }
    }
    return null;
  }

  static String? _readEmergencyNumber(dynamic value) {
    if (value is String) {
      return value;
    }
    if (value is Map<String, dynamic>) {
      final number = value['number'] ?? value['phone'] ?? value['value'];
      if (number is String) {
        return number;
      }
    }
    return null;
  }
}

class TenantOpeningHour {
  const TenantOpeningHour({
    required this.day,
    required this.opens,
    required this.closes,
    required this.closed,
    required this.note,
  });

  final String day;
  final String opens;
  final String closes;
  final bool closed;
  final String note;

  factory TenantOpeningHour.fromJson(Map<String, dynamic> json) {
    return TenantOpeningHour(
      day: _readString(json, ['day', 'weekday']),
      opens: _readString(json, ['opens', 'open', 'from']),
      closes: _readString(json, ['closes', 'close', 'to']),
      closed: _readBool(json, ['closed', 'isClosed']) ?? false,
      note: _readString(json, ['note', 'hint']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day.trim(),
      'opens': opens.trim(),
      'closes': closes.trim(),
      'closed': closed,
      'note': note.trim(),
    };
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

  static bool? _readBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        if (value.toLowerCase() == 'true') {
          return true;
        }
        if (value.toLowerCase() == 'false') {
          return false;
        }
      }
    }
    return null;
  }
}
