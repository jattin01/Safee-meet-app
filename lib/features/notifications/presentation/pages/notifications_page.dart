import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';

// PROTOTYPE MODE: this page renders mock data only — there is no API
// wiring or backend connectivity. Re-connect it to the /notifications
// endpoint before shipping.
enum _NotifType { verification, meeting, review, sos, subscription }

class _NotifItem {
  final String title;
  final String body;
  final _NotifType type;
  final String time;
  bool read;
  final String? actionLabel;
  final String? actionRoute;

  _NotifItem({
    required this.title,
    required this.body,
    required this.type,
    required this.time,
    required this.read,
    this.actionLabel,
    this.actionRoute,
  });
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<_NotifItem> _items = [
    _NotifItem(
      title: 'Level 2 Verification Complete',
      body: 'Your background check has been approved. Your Level 2 Verified badge is now active.',
      type: _NotifType.verification,
      time: '2m ago',
      read: false,
      actionLabel: 'View Status',
      actionRoute: AppRoutes.verificationStatus,
    ),
    _NotifItem(
      title: 'Meeting Request from Sarah M.',
      body: 'Sarah Mitchell has sent you a meeting invitation for Jun 14, 2:00 PM at Downtown Café.',
      type: _NotifType.meeting,
      time: '15m ago',
      read: false,
      actionLabel: 'View Invite',
      actionRoute: AppRoutes.meetings,
    ),
    _NotifItem(
      title: 'New Review Received',
      body: 'James Carter left you a 5-star review: "Great seller! Smooth transaction."',
      type: _NotifType.review,
      time: '1h ago',
      read: false,
    ),
    _NotifItem(
      title: 'SOS Alert Test',
      body: 'Your emergency SOS test was successful. All 3 trusted contacts were notified.',
      type: _NotifType.sos,
      time: '3h ago',
      read: true,
    ),
    _NotifItem(
      title: 'Premium Plan Renews Soon',
      body: 'Your Premium subscription renews on July 10, 2026. \$19.99 will be charged.',
      type: _NotifType.subscription,
      time: 'Yesterday',
      read: true,
      actionLabel: 'Manage Plan',
      actionRoute: AppRoutes.subscription,
    ),
  ];

  void _markAllRead() {
    setState(() {
      for (final item in _items) {
        item.read = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: Column(
        children: [
          DarkScreenHeader(
            title: 'Notifications',
            trailing: GestureDetector(
              onTap: _markAllRead,
              child: Text(
                'Mark all read',
                style: GoogleFonts.inter(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => Future.delayed(const Duration(milliseconds: 700)),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                itemCount: _items.length,
                itemBuilder: (_, i) => _NotificationCard(item: _items[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

(Color, IconData) _typeStyle(_NotifType type) {
  switch (type) {
    case _NotifType.verification:
      return (AppColors.success, Icons.shield);
    case _NotifType.meeting:
      return (AppColors.blue, Icons.calendar_today);
    case _NotifType.review:
      return (AppColors.warning, Icons.star);
    case _NotifType.sos:
      return (AppColors.primary, Icons.warning_amber_rounded);
    case _NotifType.subscription:
      return (AppColors.purple, Icons.notifications);
  }
}

class _NotificationCard extends StatelessWidget {
  final _NotifItem item;
  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _typeStyle(item.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(item.time, style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                    if (!item.read) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 3),
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(item.body, style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                if (item.actionLabel != null) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      if (item.actionRoute != null) context.push(item.actionRoute!);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.actionLabel!,
                        style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
