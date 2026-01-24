import 'app_permissions.dart';
import '../../api/api_client.dart';

class PermissionsService {
  PermissionsService(this._apiClient);

  final ApiClient _apiClient;

  Future<AppPermissions> getPermissions() async {
    try {
      final data = await _apiClient.getJsonFlexible(
        '/permissions',
      );
      final payload = _extractPayload(data);
      final canCreate = payload['canCreate'];
      final createPermissions = _parseCreatePermissions(canCreate);
      return AppPermissions(
        role: payload['role']?.toString() ?? 'USER',
        isAdmin: _readBool(payload['isAdmin']) ?? false,
        canCreate: createPermissions,
        canModerateUserContent:
            _readBool(payload['canModerateUserContent']) ?? false,
        canManageResidents: _readBool(payload['canManageResidents']) ?? false,
        canGenerateActivationCodes:
            _readBool(payload['canGenerateActivationCodes']) ?? false,
        canManageRoles: _readBool(payload['canManageRoles']) ?? false,
      );
    } catch (_) {
      return AppPermissions.empty;
    }
  }

  AppPermissions _mapPermissions(Map<String, dynamic> payload) {
    final isAdmin = _readBool(payload['isAdmin']) ?? false;
    final legacyManage = _readBool(payload['canManageContent']) ??
        _readBool(payload['admin']) ??
        _readBool(payload['canManage']);
    final canCreateEvents =
        _readBool(payload['canCreateEvents']) ?? legacyManage;
    final canCreatePosts =
        _readBool(payload['canCreatePosts']) ?? legacyManage;
    final canCreateNews = _readBool(payload['canCreateNews']) ?? legacyManage;
    final canCreateWarnings =
        _readBool(payload['canCreateWarnings']) ?? legacyManage;
    final canModerate = _readBool(payload['canModerate']) ?? legacyManage;
    final canManageResidents = _readBool(payload['canManageResidents']);
    final canGenerateActivationCodes =
        _readBool(payload['canGenerateActivationCodes']);

    final roleValue = payload['role'];
    final parsedRole = _parseRole(roleValue);
    final inferredRole = parsedRole ?? _inferRole(
      isAdmin: isAdmin,
      canCreateEvents: canCreateEvents,
      canCreatePosts: canCreatePosts,
      canCreateNews: canCreateNews,
      canCreateWarnings: canCreateWarnings,
      canModerate: canModerate,
    );

    return AppPermissions(
      role: inferredRole,
      isAdmin: isAdmin,
      canCreateEvents: canCreateEvents ?? false,
      canCreatePosts: canCreatePosts ?? false,
      canCreateNews: canCreateNews ?? false,
      canCreateWarnings: canCreateWarnings ?? false,
      canModerate: canModerate ?? false,
      canManageResidents: canManageResidents ?? false,
      canGenerateActivationCodes: canGenerateActivationCodes ?? false,
    );
  }

  AppRole? _parseRole(dynamic value) {
    if (value is! String) {
      return null;
    }
    switch (value.toUpperCase()) {
      case 'ADMIN':
        return AppRole.admin;
      case 'STAFF':
        return AppRole.staff;
      case 'USER':
        return AppRole.user;
      default:
        return null;
    }
  }

  AppRole _inferRole({
    required bool isAdmin,
    required bool? canCreateEvents,
    required bool? canCreatePosts,
    required bool? canCreateNews,
    required bool? canCreateWarnings,
    required bool? canModerate,
  }) {
    if (isAdmin) {
      return AppRole.admin;
    }
    final hasContentPermission =
        (canCreateEvents ?? false) ||
            (canCreatePosts ?? false) ||
            (canCreateNews ?? false) ||
            (canCreateWarnings ?? false) ||
            (canModerate ?? false);
    return hasContentPermission ? AppRole.staff : AppRole.user;
  }

  Map<String, dynamic> _extractPayload(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'] ?? data['permissions'];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
      return data;
    }
    return const <String, dynamic>{};
  }

  bool? _readBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      if (value.toLowerCase() == 'true') {
        return true;
      }
      if (value.toLowerCase() == 'false') {
        return false;
      }
    }
    if (value is num) {
      return value != 0;
    }
    return null;
  }

  CreatePermissions _parseCreatePermissions(dynamic value) {
    if (value is Map<String, dynamic>) {
      return CreatePermissions(
        marketplace: _readBool(value['marketplace']) ?? false,
        help: _readBool(value['help']) ?? false,
        movingClearance: _readBool(value['movingClearance']) ?? false,
        cafeMeetup: _readBool(value['cafeMeetup']) ?? false,
        kidsMeetup: _readBool(value['kidsMeetup']) ?? false,
        apartmentSearch: _readBool(value['apartmentSearch']) ?? false,
        lostFound: _readBool(value['lostFound']) ?? false,
        rideSharing: _readBool(value['rideSharing']) ?? false,
        jobsLocal: _readBool(value['jobsLocal']) ?? false,
        volunteering: _readBool(value['volunteering']) ?? false,
        giveaway: _readBool(value['giveaway']) ?? false,
        skillExchange: _readBool(value['skillExchange']) ?? false,
        officialNews: _readBool(value['officialNews']) ?? false,
        officialWarnings: _readBool(value['officialWarnings']) ?? false,
        officialEvents: _readBool(value['officialEvents']) ?? false,
      );
    }
    return CreatePermissions.empty;
  }
}
