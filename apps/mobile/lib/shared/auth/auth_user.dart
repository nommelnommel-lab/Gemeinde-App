class AuthUser {
  const AuthUser({
    required this.id,
    required this.tenantId,
    required this.residentId,
    required this.displayName,
    required this.email,
  });

  final String id;
  final String tenantId;
  final String residentId;
  final String displayName;
  final String email;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      residentId: json['residentId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}
