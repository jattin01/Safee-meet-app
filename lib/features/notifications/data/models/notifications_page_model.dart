import '../../domain/entities/notification_entity.dart';
import 'notification_model.dart';

class NotificationsPageModel {
  final List<NotificationModel> notifications;
  final int currentPage;
  final int lastPage;
  final String? nextPageUrl;

  const NotificationsPageModel({
    required this.notifications,
    required this.currentPage,
    required this.lastPage,
    this.nextPageUrl,
  });

  factory NotificationsPageModel.fromJson(Map<String, dynamic> json) {
    // Other endpoints in this API sometimes wrap paginated payloads in
    // {"success": true, "data": <laravel paginate() object>} and sometimes
    // return the paginate() object directly — support both instead of
    // assuming one shape.
    final root = _paginationRoot(json);
    final items = (root['data'] as List<dynamic>? ?? const [])
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return NotificationsPageModel(
      notifications: items,
      currentPage: (root['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (root['last_page'] as num?)?.toInt() ?? 1,
      nextPageUrl: root['next_page_url'] as String?,
    );
  }

  static Map<String, dynamic> _paginationRoot(Map<String, dynamic> json) {
    if (json.containsKey('current_page')) return json;
    final nested = json['data'];
    if (nested is Map && nested.containsKey('current_page')) {
      return Map<String, dynamic>.from(nested);
    }
    return json;
  }

  NotificationsPageEntity toEntity() => NotificationsPageEntity(
        notifications: notifications.map((n) => n.toEntity()).toList(),
        currentPage: currentPage,
        lastPage: lastPage,
        nextPageUrl: nextPageUrl,
      );
}
