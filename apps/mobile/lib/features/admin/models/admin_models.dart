class AdminResident {
  AdminResident({
    required this.id,
    required this.displayName,
    required this.status,
    required this.createdAt,
    required this.postalCode,
    required this.houseNumber,
  });

  final String id;
  final String displayName;
  final String status;
  final String createdAt;
  final String postalCode;
  final String houseNumber;

  factory AdminResident.fromJson(Map<String, dynamic> json) {
    return AdminResident(
      id: (json['id'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      postalCode: (json['postalCode'] ?? '').toString(),
      houseNumber: (json['houseNumber'] ?? '').toString(),
    );
  }
}

class AdminResidentInput {
  AdminResidentInput({
    required this.firstName,
    required this.lastName,
    required this.postalCode,
    required this.houseNumber,
  });

  final String firstName;
  final String lastName;
  final String postalCode;
  final String houseNumber;

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'postalCode': postalCode,
        'houseNumber': houseNumber,
      };
}

class AdminImportError {
  AdminImportError({required this.row, required this.message});

  final int row;
  final String message;

  factory AdminImportError.fromJson(Map<String, dynamic> json) {
    return AdminImportError(
      row: (json['row'] ?? 0) as int,
      message: (json['message'] ?? '').toString(),
    );
  }
}

class AdminImportSummary {
  AdminImportSummary({
    required this.created,
    required this.skipped,
    required this.failed,
    required this.errors,
  });

  final int created;
  final int skipped;
  final int failed;
  final List<AdminImportError> errors;

  factory AdminImportSummary.fromJson(Map<String, dynamic> json) {
    return AdminImportSummary(
      created: (json['created'] ?? 0) as int,
      skipped: (json['skipped'] ?? 0) as int,
      failed: (json['failed'] ?? 0) as int,
      errors: (json['errors'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AdminImportError.fromJson)
          .toList(),
    );
  }
}

class AdminActivationCode {
  AdminActivationCode({
    required this.residentId,
    required this.code,
    required this.expiresAt,
  });

  final String residentId;
  final String code;
  final String expiresAt;

  factory AdminActivationCode.fromJson(Map<String, dynamic> json) {
    return AdminActivationCode(
      residentId: (json['residentId'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      expiresAt: (json['expiresAt'] ?? '').toString(),
    );
  }
}

class AdminActivationSkip {
  AdminActivationSkip({
    required this.residentId,
    required this.reason,
  });

  final String residentId;
  final String reason;

  factory AdminActivationSkip.fromJson(Map<String, dynamic> json) {
    return AdminActivationSkip(
      residentId: (json['residentId'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
    );
  }
}

class BulkActivationResult {
  BulkActivationResult({
    required this.created,
    required this.skipped,
  });

  final List<AdminActivationCode> created;
  final List<AdminActivationSkip> skipped;

  factory BulkActivationResult.fromJson(Map<String, dynamic> json) {
    return BulkActivationResult(
      created: (json['created'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AdminActivationCode.fromJson)
          .toList(),
      skipped: (json['skipped'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AdminActivationSkip.fromJson)
          .toList(),
    );
  }
}
