import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/shared/widgets/primary_button.dart';
import '../../data/mock_meetings.dart';
import '../../domain/entities/meeting_entity.dart';

// PROTOTYPE MODE: this page renders mock data (MockMeetings) only — there
// is no MeetingsBloc wiring or backend connectivity. Re-connect it to
// MeetingsBloc (MeetingsLoadRequested) before shipping.
class MeetingsListPage extends StatefulWidget {
  const MeetingsListPage({super.key});

  @override
  State<MeetingsListPage> createState() => _MeetingsListPageState();
}

class _MeetingsListPageState extends State<MeetingsListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<MeetingEntity> _meetings = MockMeetings.all;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // Prototype: simulates a network refresh against the mock dataset so the
  // pull-to-refresh UX can still be demonstrated without a backend.
  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _meetings = List.of(MockMeetings.all));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcoming = _meetings
        .where((m) =>
            m.scheduledAt.isAfter(now) ||
            m.status == MeetingStatus.scheduled ||
            m.status == MeetingStatus.enRoute ||
            m.status == MeetingStatus.arrived)
        .toList();
    final past = _meetings
        .where((m) =>
            m.status == MeetingStatus.completed ||
            m.status == MeetingStatus.cancelled)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: const Text(
          'My Meetings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _MeetingsList(
            meetings: upcoming,
            onRefresh: _refresh,
            emptyMessage: 'No upcoming meetings',
            emptyIcon: Icons.calendar_today_outlined,
          ),
          _MeetingsList(
            meetings: past,
            onRefresh: _refresh,
            emptyMessage: 'No past meetings',
            emptyIcon: Icons.history,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.meetingSetup),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Schedule',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _MeetingsList extends StatelessWidget {
  final List<MeetingEntity> meetings;
  final Future<void> Function() onRefresh;
  final String emptyMessage;
  final IconData emptyIcon;

  const _MeetingsList({
    required this.meetings,
    required this.onRefresh,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (meetings.isEmpty) {
      return _EmptyState(message: emptyMessage, icon: emptyIcon);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: meetings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _MeetingCard(meeting: meetings[i]),
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final MeetingEntity meeting;
  const _MeetingCard({required this.meeting});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(meeting.status);
    final statusLabel = _statusLabel(meeting.status);

    return GestureDetector(
      onTap: () => context.push('${AppRoutes.activeMeeting}/${meeting.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkBg2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      meeting.partnerInitials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meeting.partnerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meeting.purpose.label,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: DateFormat('MMM d, yyyy').format(meeting.scheduledAt),
                ),
                const SizedBox(width: 16),
                _InfoChip(
                  icon: Icons.access_time,
                  label: DateFormat('h:mm a').format(meeting.scheduledAt),
                ),
                const Spacer(),
                _InfoChip(
                  icon: Icons.location_on_outlined,
                  label: meeting.location.length > 16
                      ? '${meeting.location.substring(0, 16)}…'
                      : meeting.location,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(MeetingStatus s) {
    switch (s) {
      case MeetingStatus.scheduled:
        return AppColors.blue;
      case MeetingStatus.enRoute:
        return AppColors.warning;
      case MeetingStatus.arrived:
        return AppColors.success;
      case MeetingStatus.completed:
        return AppColors.textTertiary;
      case MeetingStatus.cancelled:
        return AppColors.error;
    }
  }

  String _statusLabel(MeetingStatus s) {
    switch (s) {
      case MeetingStatus.scheduled:
        return 'Scheduled';
      case MeetingStatus.enRoute:
        return 'En Route';
      case MeetingStatus.arrived:
        return 'Arrived';
      case MeetingStatus.completed:
        return 'Completed';
      case MeetingStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const _EmptyState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textTertiary, size: 56),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Schedule a Meeting',
            onPressed: () => context.push(AppRoutes.meetingSetup),
          ),
        ],
      ),
    );
  }
}

