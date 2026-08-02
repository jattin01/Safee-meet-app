import 'package:equatable/equatable.dart';

/// A single notification from GET /v1/notifications. [type] and [data] are
/// kept as raw, dynamic values (not a closed enum) so new notification
/// types the backend introduces later show up without an app update — the
/// centralized navigation handler is the only place that interprets [type].
class NotificationEntity extends Equatable {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  NotificationEntity copyWith({bool? isRead}) => NotificationEntity(
        id: id,
        type: type,
        title: title,
        body: body,
        data: data,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, type, title, body, data, isRead, createdAt];
}

/// One page of GET /v1/notifications, mirroring the API's pagination
/// metadata so the UI can decide when to fetch the next page.
class NotificationsPageEntity extends Equatable {
  final List<NotificationEntity> notifications;
  final int currentPage;
  final int lastPage;
  final String? nextPageUrl;

  const NotificationsPageEntity({
    required this.notifications,
    required this.currentPage,
    required this.lastPage,
    this.nextPageUrl,
  });

  bool get hasMore => nextPageUrl != null && currentPage < lastPage;

  @override
  List<Object?> get props =>
      [notifications, currentPage, lastPage, nextPageUrl];
}
