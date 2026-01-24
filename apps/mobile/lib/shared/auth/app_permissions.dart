import 'package:flutter/widgets.dart';

enum AppRole { user, staff, admin }

@immutable
class AppPermissions {
  const AppPermissions({
    required this.role,
    required this.isAdmin,
    required this.canCreateEvents,
    required this.canCreatePosts,
    required this.canCreateNews,
    required this.canCreateWarnings,
    required this.canModerate,
    required this.canManageResidents,
    required this.canGenerateActivationCodes,
  });

  const AppPermissions.empty()
      : role = AppRole.user,
        isAdmin = false,
        canCreateEvents = false,
        canCreatePosts = false,
        canCreateNews = false,
        canCreateWarnings = false,
        canModerate = false,
        canManageResidents = false,
        canGenerateActivationCodes = false;

  final AppRole role;
  final bool isAdmin;
  final bool canCreateEvents;
  final bool canCreatePosts;
  final bool canCreateNews;
  final bool canCreateWarnings;
  final bool canModerate;
  final bool canManageResidents;
  final bool canGenerateActivationCodes;

  bool get isStaffMode => role != AppRole.user;

  bool get canManageContent =>
      canCreateEvents ||
      canCreatePosts ||
      canCreateNews ||
      canCreateWarnings ||
      canModerate;

  AppPermissions copyWith({
    AppRole? role,
    bool? isAdmin,
    bool? canCreateEvents,
    bool? canCreatePosts,
    bool? canCreateNews,
    bool? canCreateWarnings,
    bool? canModerate,
    bool? canManageResidents,
    bool? canGenerateActivationCodes,
  }) {
    return AppPermissions(
      role: role ?? this.role,
      isAdmin: isAdmin ?? this.isAdmin,
      canCreateEvents: canCreateEvents ?? this.canCreateEvents,
      canCreatePosts: canCreatePosts ?? this.canCreatePosts,
      canCreateNews: canCreateNews ?? this.canCreateNews,
      canCreateWarnings: canCreateWarnings ?? this.canCreateWarnings,
      canModerate: canModerate ?? this.canModerate,
      canManageResidents: canManageResidents ?? this.canManageResidents,
      canGenerateActivationCodes:
          canGenerateActivationCodes ?? this.canGenerateActivationCodes,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppPermissions &&
            other.role == role &&
            other.isAdmin == isAdmin &&
            other.canCreateEvents == canCreateEvents &&
            other.canCreatePosts == canCreatePosts &&
            other.canCreateNews == canCreateNews &&
            other.canCreateWarnings == canCreateWarnings &&
            other.canModerate == canModerate &&
            other.canManageResidents == canManageResidents &&
            other.canGenerateActivationCodes == canGenerateActivationCodes;
  }

  @override
  int get hashCode => Object.hash(
        role,
        isAdmin,
        canCreateEvents,
        canCreatePosts,
        canCreateNews,
        canCreateWarnings,
        canModerate,
        canManageResidents,
        canGenerateActivationCodes,
      );
}

class AppPermissionsScope extends StatefulWidget {
  const AppPermissionsScope({
    super.key,
    required this.child,
    this.permissions = const AppPermissions.empty(),
  });

  final Widget child;
  final AppPermissions permissions;

  static AppPermissions permissionsOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_AppPermissionsInherited>();
    assert(scope != null, 'No AppPermissionsScope found in context');
    return scope!.permissions;
  }

  static AppPermissions? maybePermissionsOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_AppPermissionsInherited>();
    return scope?.permissions;
  }

  static AppPermissionsScopeState controllerOf(BuildContext context) {
    final state = context.findAncestorStateOfType<AppPermissionsScopeState>();
    assert(state != null, 'No AppPermissionsScope found in context');
    return state!;
  }

  @override
  State<AppPermissionsScope> createState() => AppPermissionsScopeState();
}

class AppPermissionsScopeState extends State<AppPermissionsScope> {
  late AppPermissions _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = widget.permissions;
  }

  @override
  void didUpdateWidget(AppPermissionsScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.permissions != widget.permissions) {
      _permissions = widget.permissions;
    }
  }

  void setPermissions(AppPermissions permissions) {
    setState(() {
      _permissions = permissions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AppPermissionsInherited(
      permissions: _permissions,
      child: widget.child,
    );
  }
}

class _AppPermissionsInherited extends InheritedWidget {
  const _AppPermissionsInherited({
    required this.permissions,
    required super.child,
  });

  final AppPermissions permissions;

  @override
  bool updateShouldNotify(_AppPermissionsInherited oldWidget) {
    return permissions != oldWidget.permissions;
  }
}
