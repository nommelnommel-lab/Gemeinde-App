import '../../events/models/event.dart';

enum FeedItemType { event, meetup, warning, news }

class FeedItem {
  const FeedItem({
    required this.type,
    required this.title,
    required this.body,
    required this.date,
    this.location,
    this.event,
  });

  final FeedItemType type;
  final String title;
  final String body;
  final DateTime date;
  final String? location;
  final Event? event;
}
