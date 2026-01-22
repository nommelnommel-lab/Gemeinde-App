import 'package:flutter/widgets.dart';

@immutable
class AppPermissions {
  const AppPermissions({required this.canManageContent});

  final bool canManageContent;

  AppPermissions copyWith({bool? canManageContent}) {
    return AppPermissions(
      canManageContent: canManageContent ?? this.canManageContent,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppPermissions && other.canManageContent == canManageContent;
  }

  @override
  int get hashCode => canManageContent.hashCode;
}

class AppPermissionsScope extends StatefulWidget {
  const AppPermissionsScope({
    super.key,
    required this.child,
    this.permissions = const AppPermissions(canManageContent: false),
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

  void setCanManageContent(bool value) {
    setState(() {
      _permissions = _permissions.copyWith(canManageContent: value);
    });
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
