import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/dependency_injection/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/shared/widgets/app_snackbar.dart';
import '../../../../core/shared/utils/safe_bottom_padding.dart';
import '../../../gps_tracking/presentation/bloc/gps_tracking_bloc.dart';
import '../../../messaging/domain/entities/message_entity.dart';
import '../../../profile/presentation/pages/add_review_page.dart';
import '../../domain/entities/emergency_share_entity.dart';
import '../../domain/entities/meeting_entity.dart';
import '../../domain/repositories/meetings_repository.dart';
import '../bloc/emergency_share_bloc.dart';

class LiveLocationPage extends StatefulWidget {
  final String? meetingId;
  const LiveLocationPage({super.key, this.meetingId});

  @override
  State<LiveLocationPage> createState() => _LiveLocationPageState();
}

class _LiveLocationPageState extends State<LiveLocationPage> {
  static const _locationPollEvery = 10; // seconds

  Timer? _timer;
  bool _ending = false;
  int _tick = 0;

  // The emergency-share endpoint only ever returns successfully while the
  // meeting is 'scheduled' (backend rejects anything else with a 422), so it
  // can never itself report a 'cancelled'/'completed' status. GET
  // /v1/meetings/{id} has no such restriction and returns the real status
  // regardless — polling it alongside emergency-share is how the *other*
  // participant's screen learns the meeting was cancelled/ended without
  // relying on guessing at a backend error message.
  bool _statusHandled = false;

  // Same overlap risk as EmergencyShareBloc's own guard (see its comment)
  // but this call isn't routed through a bloc at all — it's fired directly
  // from the 1-second Timer below, un-awaited, with nothing queuing it. If
  // a response ever takes ≥10s, the next poll would otherwise fire a
  // duplicate request on top of the still-running one.
  bool _statusFetching = false;
  late final GpsTrackingBloc _gpsTrackingBloc;

  // Exposed so child widgets (_TrustedContactsCardState) can read it
  // via findAncestorStateOfType<_LiveLocationPageState>()
  String? get _meetingId => widget.meetingId;

  @override
  void initState() {
    super.initState();
    _gpsTrackingBloc = context.read<GpsTrackingBloc>();
    final meetingId = widget.meetingId;
    if (meetingId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<EmergencyShareBloc>().add(EmergencyShareRequested(meetingId));
        // Starts streaming the device's live GPS position and pinging it to
        // the backend (POST /v1/meetings/{id}/location) for the duration of
        // the meeting — see GpsTrackingBloc.
        context.read<GpsTrackingBloc>().add(GpsTrackingStarted(meetingId));
        _fetchMeetingStatus(meetingId);
      });
    }
    // Ticks once a second: always redraws the countdown to the scheduled
    // meeting time (no state to mutate for that — build() just re-reads
    // DateTime.now()), and every _locationPollEvery ticks also re-fetches
    // emergency-share so the *other* participant's latest GPS ping (and the
    // distance/map derived from it) stays live without a manual refresh —
    // EmergencyShareBloc only blanks the screen on the very first load, so
    // this repeated fetch just updates the existing data in place. The same
    // tick also re-checks the real meeting status (see _fetchMeetingStatus)
    // so a cancellation by either Host or Guest surfaces here automatically.
    final emergencyShareBloc = context.read<EmergencyShareBloc>();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _tick++);
      if (meetingId != null && _tick % _locationPollEvery == 0) {
        emergencyShareBloc.add(EmergencyShareRequested(meetingId));
        _fetchMeetingStatus(meetingId);
      }
    });
  }

  Future<void> _fetchMeetingStatus(String meetingId) async {
    if (_statusFetching) return;
    _statusFetching = true;
    try {
      final result = await sl<MeetingsRepository>().getMeeting(meetingId);
      if (!mounted) return;
      // A transient failure here (network blip, etc.) says nothing about
      // the meeting's status — just skip it and let the next poll retry.
      result.fold((_) {}, (meeting) => _handleMeetingStatus(meeting.status));
    } finally {
      _statusFetching = false;
    }
  }

  void _handleMeetingStatus(MeetingStatus status) {
    if (_statusHandled || !mounted) return;
    if (status == MeetingStatus.cancelled || status == MeetingStatus.declined) {
      _statusHandled = true;
      _leaveWithMessage('This meeting was cancelled.');
    } else if (status == MeetingStatus.completed) {
      _statusHandled = true;
      _leaveWithMessage('This meeting has already ended.');
    }
  }

  void _leaveWithMessage(String message) {
    if (!mounted) return;
    // Show the toast BEFORE popping, not after: AppSnackbar.info walks up
    // from this context to find the root Overlay, and calling it right
    // after context.pop() can hit this page's element while it's already
    // deactivating — a real crash (Flutter's "element._lifecycleState ==
    // _ElementLifecycle.inactive" assertion), not just theoretical. The
    // toast lives in the root overlay so it keeps displaying correctly over
    // whatever screen is visible once the pop completes.
    AppSnackbar.info(context, message);
    context.pop();
  }

  // Pull-to-refresh: re-fetches both the emergency-share data (partner
  // location, contacts) and the authoritative meeting status in one go, and
  // waits for both before the RefreshIndicator's spinner dismisses.
  Future<void> _handleRefresh() async {
    final meetingId = widget.meetingId;
    if (meetingId == null) return;
    final bloc = context.read<EmergencyShareBloc>();
    // Safety net: EmergencyShareLoaded now bumps a timestamp on every fetch
    // specifically so this always sees a distinct stream event (see that
    // class's doc comment) — but if some other, currently-unforeseen path
    // ever stalls without emitting Loaded/Error at all, this timeout still
    // guarantees the RefreshIndicator spinner stops instead of hanging
    // indefinitely, same as a successful refresh would.
    final shareDone = bloc.stream
        .firstWhere((s) => s is EmergencyShareLoaded || s is EmergencyShareError)
        .timeout(const Duration(seconds: 15), onTimeout: () => bloc.state);
    bloc.add(EmergencyShareRequested(meetingId));
    await Future.wait([shareDone, _fetchMeetingStatus(meetingId)]);
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (widget.meetingId != null) {
      _gpsTrackingBloc.add(const GpsTrackingStopped());
    }
    super.dispose();
  }

  void _showEndDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        // The app's ThemeMode is forced dark (see main.dart), so an
        // AlertDialog with no explicit backgroundColor picks up the dark
        // color scheme's surface — force it light to match this screen's
        // (light) body instead.
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('End Meeting', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to end this meeting?',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            // Guards against the dialog's barrier having already dismissed
            // it — popping an already-inactive route throws Flutter's
            // element-lifecycle assertion instead of being a harmless no-op.
            onPressed: () {
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _endMeeting();
            },
            child: Text('End Meeting', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _endMeeting() async {
    final meetingId = widget.meetingId;
    if (meetingId == null || _ending) return;
    setState(() => _ending = true);

    final result = await sl<MeetingsRepository>().endMeeting(meetingId);
    if (!mounted) return;
    setState(() => _ending = false);

    result.fold(
      (failure) => AppSnackbar.error(context, failure.message),
      (_) => _goToReviewOrMeetings(meetingId),
    );
  }

  // The meeting just ended successfully — send the user to rate the other
  // participant. Falls back to the meetings list if the partner's identity
  // (needed for AddReviewArgs) somehow isn't loaded.
  void _goToReviewOrMeetings(String meetingId) {
    final shareState = context.read<EmergencyShareBloc>().state;
    final partner =
        shareState is EmergencyShareLoaded ? shareState.data.partner : null;
    final revieweeId = int.tryParse(partner?.id ?? '');

    if (partner != null && revieweeId != null) {
      context.go(
        AppRoutes.addReview,
        extra: AddReviewArgs(
          meetingId: meetingId,
          revieweeId: revieweeId,
          revieweeName: partner.name,
        ),
      );
    } else {
      context.go('${AppRoutes.meetings}?tab=past');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.meetingId == null) {
      return _buildScaffold(null);
    }
    // Gate the whole screen on the emergency-share fetch: nothing renders
    // (partner name, contacts, location) until the data has fully loaded, so
    // the user never sees a half-populated screen.
    return BlocConsumer<EmergencyShareBloc, EmergencyShareState>(
      listener: (context, state) {
        // Backend only allows sharing 'scheduled' meetings — if the meeting
        // ended/was cancelled after the list loaded (or this was opened via
        // a stale link), bounce back with a friendly message instead of
        // stranding the user on a raw backend-error page.
        if (state is EmergencyShareError &&
            _isMeetingUnavailable(state.message) &&
            !_statusHandled) {
          _statusHandled = true;
          if (ModalRoute.of(context)?.isCurrent == true) {
            _leaveWithMessage('This meeting is over and is no longer available.');
          }
        }
      },
      builder: (context, state) {
        if (state is EmergencyShareLoaded) return _buildScaffold(state.data);
        if (state is EmergencyShareError) {
          // The listener above is already navigating away for this case —
          // avoid flashing the raw error screen in the meantime.
          if (_isMeetingUnavailable(state.message)) return _buildLoadingScreen();
          return _buildErrorScreen(state.message);
        }
        return _buildLoadingScreen();
      },
    );
  }

  bool _isMeetingUnavailable(String message) =>
      message.toLowerCase().contains('scheduled');

  // Was a hand-rolled skeleton screen — 8 separate shimmer widgets, each
  // running its own AnimationController + AnimatedBuilder every frame
  // purely for visual polish. That's real, continuous CPU/repaint work
  // competing with this screen's other live work (GPS streaming, the
  // 10s poll), and none of it makes data appear any sooner — the loaded
  // state renders the instant EmergencyShareBloc emits it either way. A
  // single standard spinner, matching every other loading state in this
  // app (see e.g. MeetingsListPage), is both simpler and cheaper.
  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 40),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context
                      .read<EmergencyShareBloc>()
                      .add(EmergencyShareRequested(widget.meetingId!)),
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back',
                      style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScaffold(EmergencyShareEntity? data) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<GpsTrackingBloc, GpsState>(
        builder: (context, gpsState) {
          final currentPosition = gpsState is GpsTracking ? gpsState : null;
          return Column(
            children: [
              _buildHeader(data, currentPosition),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _handleRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding:
                        EdgeInsets.fromLTRB(16, 16, 16, context.bottomSafePadding(32)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _MeetingProgressCard(),
                        const SizedBox(height: 12),
                        _TrustedContactsCard(contacts: data?.emergencyContacts),
                        const SizedBox(height: 12),
                        _LiveLocationCard(
                          position: currentPosition,
                          meetingLocation: data?.meeting?.location,
                        ),
                        const SizedBox(height: 12),
                        _buildActionButtons(data),
                        const SizedBox(height: 12),
                        _EndMeetingButton(loading: _ending, onTap: _showEndDialog),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(EmergencyShareEntity? data, GpsTracking? currentPosition) {
    return _Header(
      countdown: _countdownLabel(data?.meeting),
      meeting: data?.meeting,
      partner: data?.partner,
      currentPosition: currentPosition,
    );
  }

  Widget _buildActionButtons(EmergencyShareEntity? data) {
    final partner = data?.partner;
    return _ActionButtons(
      onMessage:
          partner == null ? null : () => _openChatWithPartner(context, partner),
      onSos: () => context.push(
        widget.meetingId == null
            ? AppRoutes.sos
            : '${AppRoutes.sos}/${widget.meetingId}',
      ),
    );
  }

  String _openChatWithPartner(
      BuildContext context, EmergencyShareUserEntity partner) {
    final conversation = ConversationEntity(
      id: partner.id,
      partnerId: partner.id,
      partnerName: partner.name,
      partnerVerificationLevel: 'none',
      unreadCount: 0,
      updatedAt: DateTime.now(),
    );
    context.push('${AppRoutes.chat}/${partner.id}', extra: conversation);
    return partner.id;
  }

  String _countdownLabel(EmergencyShareMeetingEntity? meeting) {
    final target = meeting == null ? null : meetingDateTime(meeting);
    if (target == null) return '--:--:--';
    var remaining = target.difference(DateTime.now());
    if (remaining.isNegative) remaining = Duration.zero;
    final h = remaining.inHours.toString().padLeft(2, '0');
    final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// `meeting_date` ("2026-08-01") and `meeting_time` ("15:30:00") are separate
// fields on the emergency-share response — combine them into one DateTime.
DateTime? meetingDateTime(EmergencyShareMeetingEntity meeting) {
  final date = DateTime.tryParse(meeting.meetingDate);
  if (date == null) return null;
  final timeSegments = meeting.meetingTime.split(':');
  final hour = int.tryParse(timeSegments.elementAtOrNull(0) ?? '') ?? 0;
  final minute = int.tryParse(timeSegments.elementAtOrNull(1) ?? '') ?? 0;
  final second = int.tryParse(timeSegments.elementAtOrNull(2) ?? '') ?? 0;
  return DateTime(date.year, date.month, date.day, hour, minute, second);
}

// ── Dark top header (appbar + meeting card + map) ──────────────────────────

class _Header extends StatelessWidget {
  final String countdown;
  final EmergencyShareMeetingEntity? meeting;
  final EmergencyShareUserEntity? partner;
  final GpsTracking? currentPosition;
  const _Header({
    required this.countdown,
    required this.meeting,
    required this.partner,
    this.currentPosition,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status bar padding
          SizedBox(height: MediaQuery.of(context).padding.top),

          // AppBar row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Active Meeting',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Meeting partner card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _PartnerCard(meeting: meeting, partner: partner),
          ),
          const SizedBox(height: 12),

          // Map with overlays
          _MapSection(
            countdown: countdown,
            meeting: meeting,
            partner: partner,
            currentPosition: currentPosition,
          ),
        ],
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final EmergencyShareMeetingEntity? meeting;
  final EmergencyShareUserEntity? partner;
  const _PartnerCard({required this.meeting, required this.partner});

  String get _partnerName => partner?.name ?? 'SAFEE User';

  String get _subtitle {
    if (meeting == null) return '';
    final parts = <String>[];
    if (meeting!.purpose != null && meeting!.purpose!.isNotEmpty) {
      parts.add(meeting!.purpose!);
    }
    final dateTime = meetingDateTime(meeting!);
    if (dateTime != null) {
      parts.add(DateFormat('MMM d, h:mm a').format(dateTime));
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkBg2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.blue,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _partnerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.textTertiary, size: 12),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          _subtitle,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
                if (meeting?.location != null && meeting!.location.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined,
                          color: AppColors.primary, size: 12),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          meeting!.location,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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

class _MapSection extends StatelessWidget {
  final String countdown;
  final EmergencyShareMeetingEntity? meeting;
  final EmergencyShareUserEntity? partner;
  final GpsTracking? currentPosition;

  const _MapSection({
    required this.countdown,
    required this.meeting,
    required this.partner,
    this.currentPosition,
  });

  bool get _hasMeetingLocation =>
      meeting?.latitude != null && meeting?.longitude != null;

  String _formatMeters(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String? get _distanceLabel {
    if (!_hasMeetingLocation) return null;

    // 1. If partner's live GPS ping is available, show partner's distance to meeting
    if (partner?.hasLocation == true) {
      final meters = Geolocator.distanceBetween(
        partner!.latitude!,
        partner!.longitude!,
        meeting!.latitude!,
        meeting!.longitude!,
      );
      return '${partner?.name?.split(' ').first ?? 'Partner'}: ${_formatMeters(meters)} away';
    }

    // 2. If current user's GPS is available, show your distance to the venue
    if (currentPosition != null) {
      final meters = Geolocator.distanceBetween(
        currentPosition!.lat,
        currentPosition!.lng,
        meeting!.latitude!,
        meeting!.longitude!,
      );
      return '${_formatMeters(meters)} to venue';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Stack(
        children: [
          _hasMeetingLocation
              ? _LiveMap(meeting: meeting!, partner: partner)
              : const _MapPlaceholder(),

          // Countdown-to-meeting badge (top-right)
          Positioned(
            top: 14,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.darkBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    countdown,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Live distance-to-meeting badge (bottom-left)
          if (_distanceLabel != null)
            Positioned(
              bottom: 12,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.darkBg,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.navigation_rounded,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _distanceLabel!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Real map: meeting point + the other participant's last known position,
// both updated live as fresh emergency-share data arrives (see the periodic
// re-fetch in _LiveLocationPageState). Falls back to _MapPlaceholder only
// when the meeting itself has no coordinates to plot at all.
// Schematic (non-georeferenced) live view: same drawn style as
// _MapPlaceholder, but driven by whether the partner's last GPS ping has
// arrived yet. Real distance/direction are shown via the badges in
// _MapSection, not by this drawing.
class _LiveMap extends StatelessWidget {
  final EmergencyShareMeetingEntity meeting;
  final EmergencyShareUserEntity? partner;
  const _LiveMap({required this.meeting, required this.partner});

  @override
  Widget build(BuildContext context) {
    final hasPartnerLocation = partner != null && partner!.hasLocation;
    return CustomPaint(
      painter: _LiveMapPainter(
        hasPartnerLocation: hasPartnerLocation,
        partnerName: partner?.name,
        meetingLocation: meeting.location,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _LiveMapPainter extends CustomPainter {
  final bool hasPartnerLocation;
  final String? partnerName;
  final String? meetingLocation;
  const _LiveMapPainter({required this.hasPartnerLocation, this.partnerName, this.meetingLocation});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFCBD5E1);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Grid blocks (simulating a map)
    final blockPaint = Paint()..color = const Color(0xFFB0BEC5);
    final blocks = [
      Rect.fromLTWH(0, 0, size.width * 0.28, size.height * 0.32),
      Rect.fromLTWH(size.width * 0.32, 0, size.width * 0.22, size.height * 0.32),
      Rect.fromLTWH(size.width * 0.58, 0, size.width * 0.24, size.height * 0.32),
      Rect.fromLTWH(size.width * 0.86, 0, size.width * 0.14, size.height * 0.32),
      Rect.fromLTWH(0, size.height * 0.38, size.width * 0.18, size.height * 0.24),
      Rect.fromLTWH(size.width * 0.22, size.height * 0.38, size.width * 0.32, size.height * 0.24),
      Rect.fromLTWH(size.width * 0.58, size.height * 0.38, size.width * 0.18, size.height * 0.24),
      Rect.fromLTWH(size.width * 0.80, size.height * 0.38, size.width * 0.20, size.height * 0.24),
      Rect.fromLTWH(0, size.height * 0.70, size.width * 0.22, size.height * 0.30),
      Rect.fromLTWH(size.width * 0.26, size.height * 0.70, size.width * 0.18, size.height * 0.30),
      Rect.fromLTWH(size.width * 0.48, size.height * 0.70, size.width * 0.28, size.height * 0.30),
      Rect.fromLTWH(size.width * 0.80, size.height * 0.70, size.width * 0.20, size.height * 0.30),
    ];
    final rr = const Radius.circular(4);
    for (final b in blocks) {
      canvas.drawRRect(RRect.fromRectAndRadius(b, rr), blockPaint);
    }

    final startX = size.width * 0.28;
    final endX = size.width * 0.72;
    final midY = size.height * 0.52;

    if (hasPartnerLocation) {
      // Route line (dashed green) — only drawn once the partner's position
      // is actually known, not while still locating.
      final dashPaint = Paint()
        ..color = const Color(0xFF22C55E)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      const dashLen = 8.0;
      const gapLen = 5.0;
      double x = startX + 16;
      while (x < endX - 16) {
        final end = math.min(x + dashLen, endX - 16.0);
        canvas.drawLine(Offset(x, midY), Offset(end, midY), dashPaint);
        x += dashLen + gapLen;
      }

      // Partner's last known location — soft halo, then blue dot with white ring
      canvas.drawCircle(Offset(startX, midY), 24,
          Paint()..color = const Color(0xFF3B82F6).withValues(alpha: 0.16));
      canvas.drawCircle(Offset(startX, midY), 10, Paint()..color = Colors.white);
      canvas.drawCircle(
          Offset(startX, midY), 7, Paint()..color = const Color(0xFF3B82F6));
      _drawBadge(canvas, Offset(startX, midY + 22),
          partnerName?.split(' ').first ?? 'Partner',
          Colors.white, const Color(0xFF1E293B), maxWidth: 80);
    } else {
      // Still waiting for the partner's first GPS ping — a hollow ring
      // instead of a solid dot, and no route line to a position we don't
      // have yet.
      canvas.drawCircle(
        Offset(startX, midY),
        9,
        Paint()
          ..color = const Color(0xFF94A3B8)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
      _drawBadge(canvas, Offset(startX, midY + 22), 'You',
          Colors.white, const Color(0xFF1E293B), maxWidth: 80);
    }

    // Meeting point pin (red) — always known, this is fixed at booking time.
    final px = endX;
    final py = midY;
    canvas.drawCircle(Offset(px, py - 2), 26,
        Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.14));
    final pinPaint = Paint()..color = const Color(0xFFEF4444);
    final pinPath = Path();
    pinPath.moveTo(px, py + 14);
    pinPath.quadraticBezierTo(px - 12, py + 2, px - 12, py - 6);
    pinPath.arcToPoint(Offset(px + 12, py - 6),
        radius: const Radius.circular(12), clockwise: false);
    pinPath.quadraticBezierTo(px + 12, py + 2, px, py + 14);
    pinPath.close();
    canvas.drawPath(pinPath, pinPaint);
    canvas.drawCircle(Offset(px, py - 6), 4, Paint()..color = Colors.white);

    // Label under the meeting location circle
    final locationLabel = meetingLocation?.isNotEmpty == true ? 'Meeting Location:\n$meetingLocation' : 'Meeting Location';
    _drawBadge(canvas, Offset(px, py + 26), locationLabel,
        Colors.white, const Color(0xFFDC2626), maxWidth: 120);
  }

  void _drawBadge(Canvas canvas, Offset point, String text, Color textColor,
      Color bgColor, {double? maxWidth}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    )..layout(maxWidth: maxWidth ?? double.infinity);

    final bgRect = Rect.fromCenter(
      center: point,
      width: tp.width + 12,
      height: tp.height + 6,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
      Paint()..color = bgColor,
    );
    tp.paint(
      canvas,
      Offset(point.dx - tp.width / 2, point.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _LiveMapPainter oldDelegate) =>
      oldDelegate.hasPartnerLocation != hasPartnerLocation ||
      oldDelegate.partnerName != partnerName;
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MapPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFCBD5E1);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Grid blocks (simulating a map)
    final blockPaint = Paint()..color = const Color(0xFFB0BEC5);
    final blocks = [
      Rect.fromLTWH(0, 0, size.width * 0.28, size.height * 0.32),
      Rect.fromLTWH(size.width * 0.32, 0, size.width * 0.22, size.height * 0.32),
      Rect.fromLTWH(size.width * 0.58, 0, size.width * 0.24, size.height * 0.32),
      Rect.fromLTWH(size.width * 0.86, 0, size.width * 0.14, size.height * 0.32),
      Rect.fromLTWH(0, size.height * 0.38, size.width * 0.18, size.height * 0.24),
      Rect.fromLTWH(size.width * 0.22, size.height * 0.38, size.width * 0.32, size.height * 0.24),
      Rect.fromLTWH(size.width * 0.58, size.height * 0.38, size.width * 0.18, size.height * 0.24),
      Rect.fromLTWH(size.width * 0.80, size.height * 0.38, size.width * 0.20, size.height * 0.24),
      Rect.fromLTWH(0, size.height * 0.70, size.width * 0.22, size.height * 0.30),
      Rect.fromLTWH(size.width * 0.26, size.height * 0.70, size.width * 0.18, size.height * 0.30),
      Rect.fromLTWH(size.width * 0.48, size.height * 0.70, size.width * 0.28, size.height * 0.30),
      Rect.fromLTWH(size.width * 0.80, size.height * 0.70, size.width * 0.20, size.height * 0.30),
    ];
    final rr = const Radius.circular(4);
    for (final b in blocks) {
      canvas.drawRRect(RRect.fromRectAndRadius(b, rr), blockPaint);
    }

    // Route line (dashed green)
    final startX = size.width * 0.28;
    final endX = size.width * 0.72;
    final midY = size.height * 0.52;

    final dashPaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const dashLen = 8.0;
    const gapLen = 5.0;
    double x = startX + 16;
    while (x < endX - 16) {
      final end = math.min(x + dashLen, endX - 16.0);
      canvas.drawLine(Offset(x, midY), Offset(end, midY), dashPaint);
      x += dashLen + gapLen;
    }

    // Current location dot — soft halo, then blue dot with white ring
    canvas.drawCircle(Offset(startX, midY), 24,
        Paint()..color = const Color(0xFF3B82F6).withValues(alpha: 0.16));
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(startX, midY), 10, dotPaint);
    final innerDotPaint = Paint()..color = const Color(0xFF3B82F6);
    canvas.drawCircle(Offset(startX, midY), 7, innerDotPaint);

    final tpUser = TextPainter(
      text: const TextSpan(
        text: 'You',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final userBgRect = Rect.fromCenter(
      center: Offset(startX, midY + 22),
      width: tpUser.width + 12,
      height: tpUser.height + 6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(userBgRect, const Radius.circular(6)),
      Paint()..color = const Color(0xFF1E293B),
    );
    tpUser.paint(
      canvas,
      Offset(startX - tpUser.width / 2, midY + 22 - tpUser.height / 2),
    );

    // Destination pin (red) — soft halo behind it too
    final px = endX;
    final py = midY;
    canvas.drawCircle(Offset(px, py - 2), 26,
        Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.14));
    final pinPaint = Paint()..color = const Color(0xFFEF4444);
    final pinPath = Path();
    pinPath.moveTo(px, py + 14);
    pinPath.quadraticBezierTo(px - 12, py + 2, px - 12, py - 6);
    pinPath.arcToPoint(Offset(px + 12, py - 6),
        radius: const Radius.circular(12), clockwise: false);
    pinPath.quadraticBezierTo(px + 12, py + 2, px, py + 14);
    pinPath.close();
    canvas.drawPath(pinPath, pinPaint);
    canvas.drawCircle(Offset(px, py - 6), 4, Paint()..color = Colors.white);

    final tpMeeting = TextPainter(
      text: const TextSpan(
        text: 'Meeting Location',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final meetingBgRect = Rect.fromCenter(
      center: Offset(px, py + 26),
      width: tpMeeting.width + 12,
      height: tpMeeting.height + 6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(meetingBgRect, const Radius.circular(6)),
      Paint()..color = const Color(0xFFDC2626),
    );
    tpMeeting.paint(
      canvas,
      Offset(px - tpMeeting.width / 2, py + 26 - tpMeeting.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Meeting Progress ────────────────────────────────────────────────────────

class _MeetingProgressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const steps = [
      (label: 'Confirmed', number: 1, done: true, active: false),
      (label: 'En Route', number: 2, done: false, active: true),
      (label: 'Arrived', number: 3, done: false, active: false),
      // (label: 'Done', number: 4, done: false, active: false),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MEETING PROGRESS',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                _ProgressStep(
                  label: steps[i].label,
                  number: steps[i].number,
                  done: steps[i].done,
                  active: steps[i].active,
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: steps[i].done
                          ? AppColors.success
                          : AppColors.border,
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

class _ProgressStep extends StatelessWidget {
  final String label;
  final int number;
  final bool done;
  final bool active;

  const _ProgressStep({
    required this.label,
    required this.number,
    required this.done,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    Color circleColor;
    Color borderColor;
    Widget child;

    if (done) {
      circleColor = AppColors.success;
      borderColor = AppColors.success;
      child = const Icon(Icons.check, color: Colors.white, size: 16);
    } else if (active) {
      circleColor = AppColors.primary;
      borderColor = AppColors.primary;
      child = Text(
        '$number',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );
    } else {
      circleColor = Colors.transparent;
      borderColor = AppColors.border;
      child = Text(
        '$number',
        style: TextStyle(
          color: AppColors.textTertiary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Center(child: child),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: done || active ? AppColors.textPrimary : AppColors.textTertiary,
            fontSize: 11,
            fontWeight: done || active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ── Trusted Contacts ────────────────────────────────────────────────────────

class _TrustedContactsCard extends StatefulWidget {
  /// null = no meeting context (static/generic screen without a meetingId).
  final List<EmergencyShareContactEntity>? contacts;

  const _TrustedContactsCard({this.contacts});

  @override
  State<_TrustedContactsCard> createState() => _TrustedContactsCardState();
}

class _TrustedContactsCardState extends State<_TrustedContactsCard> {
  Future<void> _navigateAndRefresh() async {
    await context.push(AppRoutes.emergencyContacts);
    // Auto-refresh emergency share data when returning from contacts page
    if (!mounted) return;
    final meetingId = context
        .findAncestorStateOfType<_LiveLocationPageState>()
        ?._meetingId;
    if (meetingId != null) {
      context.read<EmergencyShareBloc>().add(EmergencyShareRequested(meetingId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacts = widget.contacts;
    final hasContacts = contacts != null && contacts.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: hasContacts ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasContacts ? const Color(0xFFBBF7D0) : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _navigateAndRefresh,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: hasContacts
                            ? AppColors.success.withOpacity(0.12)
                            : AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.people_rounded,
                        color: hasContacts ? AppColors.success : AppColors.primary,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        hasContacts
                            ? 'Trusted Contacts to be Notified'
                            : 'Add Trusted Contacts',
                        style: TextStyle(
                          color: hasContacts
                              ? AppColors.success
                              : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasContacts
                            ? AppColors.success.withOpacity(0.12)
                            : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasContacts ? Icons.edit_outlined : Icons.add,
                            size: 12,
                            color: hasContacts
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            hasContacts ? 'Manage' : 'Add',
                            style: TextStyle(
                              color: hasContacts
                                  ? AppColors.success
                                  : AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (hasContacts) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: contacts
                        .map(
                          (c) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person,
                                    color: AppColors.success, size: 12),
                                const SizedBox(width: 3),
                                Text(
                                  c.fullName,
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ] else ...[
                  const SizedBox(height: 2),
                  const Text(
                    'Auto-alert contacts during emergency',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Live Location ───────────────────────────────────────────────────────────

class _LiveLocationCard extends StatefulWidget {
  final GpsTracking? position;
  final String? meetingLocation;
  const _LiveLocationCard({this.position, this.meetingLocation});

  @override
  State<_LiveLocationCard> createState() => _LiveLocationCardState();
}

class _LiveLocationCardState extends State<_LiveLocationCard> {
  String? _address;
  bool _resolving = false;
  double? _resolvedLat;
  double? _resolvedLng;

  @override
  void initState() {
    super.initState();
    _maybeResolveAddress();
  }

  @override
  void didUpdateWidget(covariant _LiveLocationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeResolveAddress();
  }

  // Re-geocodes only when we've moved meaningfully (~40m) since the last
  // resolved point — GPS ticks roughly every 10m (see GpsTrackingBloc), so
  // reverse-geocoding every single update would hammer the geocoding API
  // for no visible benefit.
  void _maybeResolveAddress() {
    final pos = widget.position;
    if (pos == null || _resolving) return;
    if (_resolvedLat != null && _resolvedLng != null) {
      final movedMeters = Geolocator.distanceBetween(
          _resolvedLat!, _resolvedLng!, pos.lat, pos.lng);
      if (movedMeters < 40) return;
    }
    _resolveAddress(pos.lat, pos.lng);
  }

  Future<void> _resolveAddress(double lat, double lng) async {
    _resolving = true;
    String resolved;
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      final p = placemarks.first;
      final parts = [p.street, p.locality, p.administrativeArea]
          .where((s) => s != null && s.isNotEmpty)
          .toList();
      resolved = parts.isNotEmpty
          ? parts.join(', ')
          : '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
    } catch (_) {
      resolved = '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
    }
    _resolving = false;
    if (!mounted) return;
    setState(() {
      _address = resolved;
      _resolvedLat = lat;
      _resolvedLng = lng;
    });
  }

  String get _locationLabel {
    final pos = widget.position;
    if (pos == null) return 'Acquiring your location…';
    return _address ??
        '${pos.lat.toStringAsFixed(5)}, ${pos.lng.toStringAsFixed(5)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.location_on, color: AppColors.blue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Live Location Active',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Sharing',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _locationLabel,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Buttons ──────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final VoidCallback? onMessage;
  final VoidCallback onSos;
  const _ActionButtons({required this.onMessage, required this.onSos});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.chat_bubble_outline,
            label: 'Message',
            bgColor: Colors.white,
            fgColor: AppColors.textPrimary,
            borderColor: AppColors.border,
            onTap: onMessage ?? () {},
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _ActionButton(
            icon: Icons.warning_amber_rounded,
            label: 'Emergency SOS',
            bgColor: const Color(0xFFFFF1F2),
            fgColor: AppColors.error,
            borderColor: const Color(0xFFFECACA),
            onTap: onSos,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color fgColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.fgColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: fgColor, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── End Meeting ─────────────────────────────────────────────────────────────

class _EndMeetingButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _EndMeetingButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.textPrimary),
                )
              : const Text(
                  'End Meeting',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}
