import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../data/mock_meetings.dart';
import '../../domain/entities/meeting_entity.dart';

// PROTOTYPE MODE: this page renders mock data (MockMeetings) only — there
// is no MeetingsBloc wiring or backend connectivity. Re-connect it to
// MeetingsBloc (MeetingLoadRequested / MeetingStatusUpdateRequested /
// MeetingEndRequested) before shipping.
class ActiveMeetingPage extends StatefulWidget {
  final String meetingId;
  const ActiveMeetingPage({super.key, required this.meetingId});

  @override
  State<ActiveMeetingPage> createState() => _ActiveMeetingPageState();
}

class _ActiveMeetingPageState extends State<ActiveMeetingPage> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  late MeetingStatus _status;

  @override
  void initState() {
    super.initState();
    _status = MockMeetings.byId(widget.meetingId).status;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meeting = MockMeetings.byId(widget.meetingId);
    return _MeetingView(
      meeting: meeting,
      status: _status,
      elapsed: _elapsed,
      onStatusUpdate: (status) => setState(() => _status = status),
      onEnd: () => _showEndDialog(context),
    );
  }

  void _showEndDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBg2,
        title: const Text('End Meeting', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to end this meeting?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(AppRoutes.dashboardHome);
            },
            child: Text('End Meeting', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _MeetingView extends StatelessWidget {
  final MeetingEntity meeting;
  final MeetingStatus status;
  final Duration elapsed;
  final ValueChanged<MeetingStatus> onStatusUpdate;
  final VoidCallback onEnd;

  const _MeetingView({
    required this.meeting,
    required this.status,
    required this.elapsed,
    required this.onStatusUpdate,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        title: const Text(
          'Active Meeting',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded, color: AppColors.primary),
            onPressed: () => context.push(AppRoutes.sos),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PartnerCard(meeting: meeting),
            const SizedBox(height: 16),
            _TimerCard(elapsed: elapsed),
            const SizedBox(height: 16),
            _StatusTracker(currentStatus: status, onUpdate: onStatusUpdate),
            const SizedBox(height: 16),
            _LocationCard(),
            const SizedBox(height: 28),
            OutlinedButton(
              onPressed: onEnd,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'End Meeting',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final MeetingEntity meeting;
  const _PartnerCard({required this.meeting});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.7), AppColors.primary],
              ),
            ),
            child: Center(
              child: Text(
                meeting.partnerInitials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
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
                  'Meeting with',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                ),
                Text(
                  meeting.partnerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  DateFormat('EEE, MMM d · h:mm a').format(meeting.scheduledAt),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Live',
              style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  final Duration elapsed;
  const _TimerCard({required this.elapsed});

  @override
  Widget build(BuildContext context) {
    final h = elapsed.inHours.toString().padLeft(2, '0');
    final m = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.darkBg2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Meeting Duration',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            '$h:$m:$s',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTracker extends StatelessWidget {
  final MeetingStatus currentStatus;
  final ValueChanged<MeetingStatus> onUpdate;

  const _StatusTracker({required this.currentStatus, required this.onUpdate});

  static const _steps = [
    (status: MeetingStatus.scheduled, label: 'Confirmed'),
    (status: MeetingStatus.enRoute, label: 'En Route'),
    (status: MeetingStatus.arrived, label: 'Arrived'),
    (status: MeetingStatus.completed, label: 'Done'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBg2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Meeting Progress',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (int i = 0; i < _steps.length; i++) ...[
                _StepItem(
                  label: _steps[i].label,
                  done: currentStatus.index >= _steps[i].status.index,
                  active: currentStatus == _steps[i].status,
                  onTap: i == currentStatus.index + 1
                      ? () => onUpdate(_steps[i].status)
                      : null,
                ),
                if (i < _steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: currentStatus.index > _steps[i].status.index
                          ? AppColors.success
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String label;
  final bool done;
  final bool active;
  final VoidCallback? onTap;

  const _StepItem({
    required this.label,
    required this.done,
    required this.active,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = done || active ? AppColors.success : AppColors.textTertiary;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: done
                ? Icon(Icons.check, color: color, size: 14)
                : active
                    ? Container(
                        margin: const EdgeInsets.all(5),
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      )
                    : null,
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 9)),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.darkBg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, color: AppColors.textTertiary, size: 48),
            const SizedBox(height: 8),
            Text(
              'Live location map',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
