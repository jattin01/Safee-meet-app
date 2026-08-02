import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_routes.dart';
import '../domain/entities/notification_entity.dart';

/// Single place that maps a notification's `type` (+ its `data` payload) to
/// a screen. The notification card itself never decides where to navigate —
/// it just calls [handleNotificationTap] — so adding a new notification
/// type only means adding one case here, not touching the UI.
void handleNotificationTap(BuildContext context, NotificationEntity notification) {
  final data = notification.data;

  switch (notification.type) {
    case 'meeting_approved':
      final meetingId = data['meeting_id']?.toString();
      if (meetingId != null && meetingId.isNotEmpty) {
        context.push('${AppRoutes.liveLocation}/$meetingId');
      }
      break;

    case 'meeting_confirmed':
      // No standalone "meeting details" screen exists yet — the closest
      // real destination is the Requests tab of the meetings list, which
      // is where a pending/requested meeting's status lives.
      context.push('${AppRoutes.meetings}?tab=requests');
      break;

    default:
      // Unknown/future notification type — no navigation. The tap still
      // marks the notification as read (handled by the caller), it just
      // doesn't route anywhere until a case is added above.
      break;
  }
}
