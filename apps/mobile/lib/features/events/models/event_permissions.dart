class EventsPermissions {
  const EventsPermissions({required this.canManageContent});

  final bool canManageContent;

  factory EventsPermissions.fromJson(Map<String, dynamic> json) {
    return EventsPermissions(
      canManageContent: json['canManageContent'] == true ||
          json['can_manage_content'] == true,
    );
  }
}
