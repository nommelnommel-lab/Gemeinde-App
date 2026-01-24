import 'package:flutter/widgets.dart';

@immutable
class CreatePermissions {
  const CreatePermissions({
    required this.marketplace,
    required this.help,
    required this.movingClearance,
    required this.cafeMeetup,
    required this.kidsMeetup,
    required this.apartmentSearch,
    required this.lostFound,
    required this.rideSharing,
    required this.jobsLocal,
    required this.volunteering,
    required this.giveaway,
    required this.skillExchange,
    required this.officialNews,
    required this.officialWarnings,
    required this.officialEvents,
  });

  final bool marketplace;
  final bool help;
  final bool movingClearance;
  final bool cafeMeetup;
  final bool kidsMeetup;
  final bool apartmentSearch;
  final bool lostFound;
  final bool rideSharing;
  final bool jobsLocal;
  final bool volunteering;
  final bool giveaway;
  final bool skillExchange;
  final bool officialNews;
  final bool officialWarnings;
  final bool officialEvents;

  static const empty = CreatePermissions(
    marketplace: false,
    help: false,
    movingClearance: false,
    cafeMeetup: false,
    kidsMeetup: false,
    apartmentSearch: false,
    lostFound: false,
    rideSharing: false,
    jobsLocal: false,
    volunteering: false,
    giveaway: false,
    skillExchange: false,
    officialNews: false,
    officialWarnings: false,
    officialEvents: false,
  );

  CreatePermissions copyWith({
    bool? marketplace,
    bool? help,
    bool? movingClearance,
    bool? cafeMeetup,
    bool? kidsMeetup,
    bool? apartmentSearch,
    bool? lostFound,
    bool? rideSharing,
    bool? jobsLocal,
    bool? volunteering,
    bool? giveaway,
    bool? skillExchange,
    bool? officialNews,
    bool? officialWarnings,
    bool? officialEvents,
  }) {
    return CreatePermissions(
      marketplace: marketplace ?? this.marketplace,
      help: help ?? this.help,
      movingClearance: movingClearance ?? this.movingClearance,
      cafeMeetup: cafeMeetup ?? this.cafeMeetup,
      kidsMeetup: kidsMeetup ?? this.kidsMeetup,
      apartmentSearch: apartmentSearch ?? this.apartmentSearch,
      lostFound: lostFound ?? this.lostFound,
      rideSharing: rideSharing ?? this.rideSharing,
      jobsLocal: jobsLocal ?? this.jobsLocal,
      volunteering: volunteering ?? this.volunteering,
      giveaway: giveaway ?? this.giveaway,
      skillExchange: skillExchange ?? this.skillExchange,
      officialNews: officialNews ?? this.officialNews,
      officialWarnings: officialWarnings ?? this.officialWarnings,
      officialEvents: officialEvents ?? this.officialEvents,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CreatePermissions &&
            other.marketplace == marketplace &&
            other.help == help &&
            other.movingClearance == movingClearance &&
            other.cafeMeetup == cafeMeetup &&
            other.kidsMeetup == kidsMeetup &&
            other.apartmentSearch == apartmentSearch &&
            other.lostFound == lostFound &&
            other.rideSharing == rideSharing &&
            other.jobsLocal == jobsLocal &&
            other.volunteering == volunteering &&
            other.giveaway == giveaway &&
            other.skillExchange == skillExchange &&
            other.officialNews == officialNews &&
            other.officialWarnings == officialWarnings &&
            other.officialEvents == officialEvents;
  }

  @override
  int get hashCode => Object.hash(
        marketplace,
        help,
        movingClearance,
        cafeMeetup,
        kidsMeetup,
        apartmentSearch,
        lostFound,
        rideSharing,
        jobsLocal,
        volunteering,
        giveaway,
        skillExchange,
        officialNews,
        officialWarnings,
        officialEvents,
      );
}

@immutable
class AppPermissions {
  const AppPermissions({
    required this.role,
    required this.isAdmin,
    required this.canCreate,
    required this.canModerateUserContent,
    required this.canManageResidents,
    required this.canGenerateActivationCodes,
    required this.canManageRoles,
  });

  final String role;
  final bool isAdmin;
  final CreatePermissions canCreate;
  final bool canModerateUserContent;
  final bool canManageResidents;
  final bool canGenerateActivationCodes;
  final bool canManageRoles;

  bool get isStaff => role != 'USER';

  static const empty = AppPermissions(
    role: 'USER',
    isAdmin: false,
    canCreate: CreatePermissions.empty,
    canModerateUserContent: false,
    canManageResidents: false,
    canGenerateActivationCodes: false,
    canManageRoles: false,
  );

  AppPermissions copyWith({
    String? role,
    bool? isAdmin,
    CreatePermissions? canCreate,
    bool? canModerateUserContent,
    bool? canManageResidents,
    bool? canGenerateActivationCodes,
    bool? canManageRoles,
  }) {
    return AppPermissions(
      role: role ?? this.role,
      isAdmin: isAdmin ?? this.isAdmin,
      canCreate: canCreate ?? this.canCreate,
      canModerateUserContent:
          canModerateUserContent ?? this.canModerateUserContent,
      canManageResidents: canManageResidents ?? this.canManageResidents,
      canGenerateActivationCodes:
          canGenerateActivationCodes ?? this.canGenerateActivationCodes,
      canManageRoles: canManageRoles ?? this.canManageRoles,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppPermissions &&
            other.role == role &&
            other.isAdmin == isAdmin &&
            other.canCreate == canCreate &&
            other.canModerateUserContent == canModerateUserContent &&
            other.canManageResidents == canManageResidents &&
            other.canGenerateActivationCodes == canGenerateActivationCodes &&
            other.canManageRoles == canManageRoles;
  }

  @override
  int get hashCode => Object.hash(
        role,
        isAdmin,
        canCreate,
        canModerateUserContent,
        canManageResidents,
        canGenerateActivationCodes,
        canManageRoles,
      );
}

class AppPermissionsScope extends StatefulWidget {
  const AppPermissionsScope({
    super.key,
    required this.child,
    this.permissions = AppPermissions.empty,
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
      _permissions = _permissions.copyWith(
        canModerateUserContent: value,
      );
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
