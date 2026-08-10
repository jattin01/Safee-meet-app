import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/dependency_injection/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/shared/utils/safe_bottom_padding.dart';
import '../../../../core/shared/widgets/app_snackbar.dart';
import '../../../../core/shared/widgets/primary_button.dart';
import '../../domain/entities/meeting_entity.dart';
import '../bloc/meetings_bloc.dart';

class MeetingsListPage extends StatelessWidget {
  final String? initialTab;
  const MeetingsListPage({super.key, this.initialTab});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<MeetingsBloc>()..add(const MeetingsLoadRequested()),
      child: _MeetingsListView(initialTab: initialTab),
    );
  }
}

class _MeetingsListView extends StatefulWidget {
  final String? initialTab;
  const _MeetingsListView({this.initialTab});

  @override
  State<_MeetingsListView> createState() => _MeetingsListViewState();
}

class _MeetingsListViewState extends State<_MeetingsListView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<MeetingEntity> _meetings = const [];

  int _getTabIndex(String? tab) => switch (tab) {
        'requests' => 1,
        'past' => 2,
        'upcoming' || _ => 0,
      };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 3,
      vsync: this,
      initialIndex: _getTabIndex(widget.initialTab),
    );
  }

  @override
  void didUpdateWidget(_MeetingsListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      final targetIndex = _getTabIndex(widget.initialTab);
      if (_tabs.index != targetIndex) {
        _tabs.animateTo(targetIndex);
      }
    }
    context.read<MeetingsBloc>().add(const MeetingsLoadRequested());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    context.read<MeetingsBloc>().add(const MeetingsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    // This screen is reached via context.go(...) from a few flows (finishing
    // a meeting review, scheduling a meeting, ending a meeting) which clear
    // the navigation stack, leaving nothing to pop back to — without this,
    // the system back button/gesture would exit the app instead of doing
    // anything. Fall back to Home when there's no previous screen.
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.home);
      },
      child: BlocConsumer<MeetingsBloc, MeetingsState>(
        listener: (context, state) {
          if (state is MeetingsError) {
            AppSnackbar.error(context, state.message);
          }
          if (state is MeetingsListLoaded) {
            setState(() => _meetings = state.meetings);
          }
        },
        builder: (context, state) {
          final upcoming = _meetings
              .where((m) =>
                  m.status == MeetingStatus.scheduled ||
                  m.status == MeetingStatus.enRoute ||
                  m.status == MeetingStatus.arrived ||
                  (m.status == MeetingStatus.pendingApproval && m.isHost))
              .toList();
          final requests = _meetings
              .where(
                  (m) => m.status == MeetingStatus.pendingApproval && !m.isHost)
              .toList();
          final past = _meetings
              .where((m) =>
                  m.status == MeetingStatus.completed ||
                  m.status == MeetingStatus.cancelled ||
                  m.status == MeetingStatus.declined ||
                  m.status == MeetingStatus.incidentReported)
              .toList();

          return Scaffold(
            backgroundColor: AppColors.lightBg,
            appBar: AppBar(
              backgroundColor: AppColors.lightBg,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
              title: const Text(
                'My Meetings',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              bottom: TabBar(
                controller: _tabs,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: [
                  const Tab(text: 'Upcoming'),
                  Tab(
                      text: requests.isEmpty
                          ? 'Requests'
                          : 'Requests (${requests.length})'),
                  const Tab(text: 'Past'),
                ],
              ),
            ),
            body: state is MeetingsLoading && _meetings.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _MeetingsList(
                        meetings: upcoming,
                        onRefresh: _refresh,
                        emptyMessage: 'No upcoming meetings',
                        emptySubtitle:
                            'Plan a safe meetup with someone in your network.',
                        emptyIcon: Icons.calendar_today_outlined,
                        showEmptyAction: true,
                        clickable: true,
                      ),
                      _MeetingsList(
                        meetings: requests,
                        onRefresh: _refresh,
                        emptyMessage: 'No pending requests',
                        emptySubtitle:
                            'Meeting requests from others will show up here.',
                        emptyIcon: Icons.mark_email_unread_outlined,
                        showActions: true,
                      ),
                      _MeetingsList(
                        meetings: past,
                        onRefresh: _refresh,
                        emptyMessage: 'No past meetings',
                        emptySubtitle:
                            "Meetings you've completed or cancelled will appear here.",
                        emptyIcon: Icons.history,
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _MeetingsList extends StatelessWidget {
  final List<MeetingEntity> meetings;
  final Future<void> Function() onRefresh;
  final String emptyMessage;
  final String emptySubtitle;
  final IconData emptyIcon;
  final bool showActions;
  final bool showEmptyAction;
  final bool clickable;

  const _MeetingsList({
    required this.meetings,
    required this.onRefresh,
    required this.emptyMessage,
    required this.emptySubtitle,
    required this.emptyIcon,
    this.showActions = false,
    this.showEmptyAction = false,
    this.clickable = false,
  });

  @override
  Widget build(BuildContext context) {
    if (meetings.isEmpty) {
      // A bare _EmptyState here has nothing scrollable for RefreshIndicator
      // to attach its pull gesture to, so an empty tab could never be
      // refreshed — only a populated list could. LayoutBuilder + a
      // minHeight-constrained SingleChildScrollView keeps the empty state
      // centered exactly as before (Center expands to fill that minimum
      // height) while making the tab always scrollable enough to pull.
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: onRefresh,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: _EmptyState(
                message: emptyMessage,
                subtitle: emptySubtitle,
                icon: emptyIcon,
                showAction: showEmptyAction,
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(20, 20, 20, context.bottomSafePadding(20)),
        itemCount: meetings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _MeetingCard(
          meeting: meetings[i],
          showActions: showActions,
          clickable: clickable,
        ),
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final MeetingEntity meeting;
  final bool showActions;
  final bool clickable;
  const _MeetingCard({
    required this.meeting,
    this.showActions = false,
    this.clickable = false,
  });

  void _onTap(BuildContext context) {
    if (meeting.status != MeetingStatus.scheduled) {
      AppSnackbar.info(
        context,
        "This meeting isn't ready yet. Please wait for approval before accessing it.",
      );
      return;
    }
    context.push('${AppRoutes.liveLocation}/${meeting.id}');
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(meeting.status);
    final statusLabel = _statusLabel(meeting.status);

    return GestureDetector(
      onTap: clickable ? () => _onTap(context) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                          color: AppColors.textPrimary,
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
            Divider(color: AppColors.border, height: 1),
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
              ],
            ),
            // Own row (rather than crammed alongside the date/time chips) so
            // the full address gets real width to wrap against instead of
            // being hard-cut to a fixed character count.
            const SizedBox(height: 10),
            Row(
              // Top-aligned rather than the Row default (center) — once the
              // address wraps to a second line, centering would float the
              // icon between both lines instead of next to the first.
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  // Nudges the icon down to sit level with the first line
                  // of text rather than the whole (now taller) block.
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(Icons.location_on_outlined,
                      color: AppColors.textSecondary, size: 14),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    meeting.location,
                    // Full address should read on the card, not truncate —
                    // wrap up to 2 lines and only ellipsize past that.
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12, height: 1.35),
                  ),
                ),
              ],
            ),
            if (showActions) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context
                          .read<MeetingsBloc>()
                          .add(MeetingDenyRequested(meeting.id)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side:
                            BorderSide(color: AppColors.error.withOpacity(0.4)),
                      ),
                      child: const Text('Deny'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context
                          .read<MeetingsBloc>()
                          .add(MeetingApproveRequested(meeting.id)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
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
      case MeetingStatus.pendingApproval:
        return AppColors.warning;
      case MeetingStatus.declined:
      case MeetingStatus.incidentReported:
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
      case MeetingStatus.pendingApproval:
        return 'Pending approval';
      case MeetingStatus.declined:
        return 'Declined';
      case MeetingStatus.incidentReported:
        return 'Incident Reported';
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
  final String subtitle;
  final IconData icon;
  final bool showAction;
  const _EmptyState({
    required this.message,
    required this.subtitle,
    required this.icon,
    this.showAction = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.12),
                    AppColors.primaryLight.withOpacity(0.06),
                  ],
                ),
              ),
              child: Icon(icon, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (showAction) ...[
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Schedule a Meeting',
                onPressed: () => context.push(AppRoutes.meetingSetup),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
