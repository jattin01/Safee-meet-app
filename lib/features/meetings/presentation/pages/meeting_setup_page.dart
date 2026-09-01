import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/dependency_injection/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/shared/utils/safe_bottom_padding.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';
import '../../../../core/shared/widgets/field_input.dart';
import '../../../../core/shared/widgets/primary_button.dart';
import '../../../member_search/domain/entities/member_entity.dart';
import '../../../member_search/presentation/pages/member_search_page.dart';
import '../../domain/entities/meeting_entity.dart';
import '../../domain/repositories/meetings_repository.dart';
import '../bloc/meetings_bloc.dart';
import 'location_picker_page.dart';
import 'package:safee_meet/core/shared/widgets/app_snackbar.dart';

/// Meetings whose status blocks their own 15-minute window — everything
/// else (completed/cancelled/declined/etc.) doesn't affect new bookings.
const _activeStatuses = {MeetingStatus.scheduled, MeetingStatus.pendingApproval};

const _activeMeetingMessage =
    'You already have an active meeting. Please create a new meeting at '
    'least 15 minutes after your current meeting.';

/// How often to re-check whether a previously-detected active meeting's
/// 15-minute block window has lapsed, so the warning clears itself (without
/// needing a refetch) once "now" passes Block Until while this page sits
/// open across that boundary.
const _activeMeetingRecheckInterval = Duration(seconds: 30);

/// Increment offered by the time-slot picker below.
const _slotMinutes = 15;

/// No longer used to force a 15-minute gap, but kept for UI snapping if needed.
DateTime _snapUpToSlot(DateTime dt) {
  final truncated = DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
  final remainder = truncated.minute % _slotMinutes;
  final hasSubMinuteRemainder = dt.second > 0 || dt.millisecond > 0;
  if (remainder == 0 && !hasSubMinuteRemainder) return truncated;
  return truncated.add(Duration(minutes: _slotMinutes - remainder));
}

class MeetingSetupPage extends StatelessWidget {
  final String? partnerId;
  final MemberEntity? partner;
  const MeetingSetupPage({super.key, this.partnerId, this.partner});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<MeetingsBloc>(),
      child: _MeetingSetupView(partnerId: partnerId, partner: partner),
    );
  }
}

class _MeetingSetupView extends StatefulWidget {
  final String? partnerId;
  final MemberEntity? partner;
  const _MeetingSetupView({this.partnerId, this.partner});

  @override
  State<_MeetingSetupView> createState() => _MeetingSetupViewState();
}

class _MeetingSetupViewState extends State<_MeetingSetupView> {
  final _locationCtrl = TextEditingController();
  final _buildingNameCtrl = TextEditingController();
  final _floorFlatCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  // Placeholder — always overwritten in initState() with the next available
  // 15-minute slot from "now", so no fixed hour is hardcoded here.
  TimeOfDay _selectedTime = TimeOfDay.now();
  MeetingPurpose _selectedPurpose = MeetingPurpose.coffee;
  late MemberEntity? _selectedPartner = widget.partner;
  double? _pickedLatitude;
  double? _pickedLongitude;

  // Populated from the meeting history API (GET /v1/meetings) — every
  // meeting that's still `scheduled` or `pending_approval` AND whose own
  // 15-minute block window hasn't lapsed yet. Each one independently
  // blocks only its own window ([scheduledAt, scheduledAt+15min)); a user
  // can have several of these at once (at different times), so this is a
  // list, not a single "the" active meeting.
  List<MeetingEntity> _activeMeetings = const [];

  // True until the initial GET /v1/meetings check resolves. The date/time
  // pickers and the submit button stay disabled during this window —
  // otherwise a user who opens either before the check completes could
  // pick (or even submit) a slot that turns out to be blocked, since
  // _activeMeetings would still read as empty at that instant.
  bool _checkingActiveMeeting = true;
  Timer? _activeMeetingRecheckTimer;

  // Meetings can now overlap, so this just returns null.
  MeetingEntity? _blockingMeetingFor(DateTime date, TimeOfDay time) {
    return null;
  }

  // Meetings can now overlap, so this just returns the snapped current time.
  DateTime _nextAvailableSlot(DateTime from) {
    return _snapUpToSlot(from);
  }

  static const _purposes = [
    (MeetingPurpose.coffee, '☕'),
    (MeetingPurpose.marketplace, '🛍️'),
    (MeetingPurpose.property, '🏠'),
    (MeetingPurpose.business, '💼'),
    (MeetingPurpose.freelance, '💻'),
    (MeetingPurpose.social, '👥'),
  ];

  @override
  void initState() {
    super.initState();
    // Default date/time is always the next available 15-minute slot from
    // right now (same logic _pickDate falls back to) — no fixed hour is
    // hardcoded, so the initial selection is always valid without requiring
    // the user to open a picker.
    final adjusted = _nextAvailableSlot(DateTime.now());
    _selectedDate = DateTime(adjusted.year, adjusted.month, adjusted.day);
    _selectedTime = TimeOfDay(hour: adjusted.hour, minute: adjusted.minute);
    _loadActiveMeetings();
  }

  void _processMeetings(List<MeetingEntity> meetings) {
    if (mounted) {
      setState(() {
        _checkingActiveMeeting = false;
        // Meetings can overlap now, so no active meeting restrictions.
        _activeMeetings = [];
      });
    }
  }

  Future<void> _loadActiveMeetings() async {
    final blocState = sl<MeetingsBloc>().state;
    if (blocState is MeetingsListLoaded) {
      _processMeetings(blocState.meetings);
      return;
    }

    final result = await sl<MeetingsRepository>().getMeetings();
    if (!mounted) return;
    result.fold(
      (_) {
        setState(() => _checkingActiveMeeting = false);
      },
      (meetings) => _processMeetings(meetings),
    );
  }

  void _pruneLapsedActiveMeetings() {
    final now = DateTime.now();
    // Block Until itself is already unrestricted (see
    // _blockingMeetingFor) — a meeting stops being "active" the instant
    // now reaches it, not only once now passes it.
    final stillActive = _activeMeetings
        .where((m) => now.isBefore(m.scheduledAt.add(const Duration(minutes: 15))))
        .toList();
    if (stillActive.length != _activeMeetings.length) {
      setState(() => _activeMeetings = stillActive);
    }
    if (stillActive.isEmpty) {
      _activeMeetingRecheckTimer?.cancel();
      _activeMeetingRecheckTimer = null;
    }
  }

  String? get _partnerId => _selectedPartner?.id ?? widget.partnerId;

  Future<void> _pickPartner() async {
    final selected = await Navigator.of(context).push<MemberEntity>(
      MaterialPageRoute(builder: (_) => const MemberSearchPage(pickerMode: true)),
    );
    if (selected != null) setState(() => _selectedPartner = selected);
  }

  Future<void> _pickLocationOnMap() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(builder: (_) => const LocationPickerPage()),
    );
    if (picked == null) return;
    setState(() {
      _locationCtrl.text = picked.address;
      _pickedLatitude = picked.latitude;
      _pickedLongitude = picked.longitude;
    });
  }

  @override
  void dispose() {
    _activeMeetingRecheckTimer?.cancel();
    _locationCtrl.dispose();
    _buildingNameCtrl.dispose();
    _floorFlatCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // True when [date]+[time] is already in the past relative to now — the
  // only reason *any* date/time is ever disabled, independent of whether
  // an active meeting exists.
  bool _isPastDateTime(DateTime date, TimeOfDay time) {
    final combined =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    // Allow the current minute by subtracting a small buffer from now,
    // otherwise selecting the current time (e.g. 14:30) at 14:30:30 will 
    // be incorrectly blocked as "in the past".
    return combined.isBefore(DateTime.now().subtract(const Duration(minutes: 1)));
  }

  // True while [date]+[time] falls inside ANY active meeting's own window
  // — [scheduledAt, scheduledAt + 15min), inclusive of that meeting's own
  // start time but *not* the +15 boundary itself, since "at least 15
  // minutes after" means exactly +15 is the first bookable slot. Times
  // earlier or later the same day, and outside every other meeting's own
  // window, are unaffected — each meeting is a narrow exclusion, not a
  // floor under the whole day.
  bool _isWithinActiveMeetingBlock(DateTime date, TimeOfDay time) =>
      _blockingMeetingFor(date, time) != null;

  bool _isDisabledDateTime(DateTime date, TimeOfDay time) =>
      _isPastDateTime(date, time) || _isWithinActiveMeetingBlock(date, time);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      // Picking a date on which the already-selected time now falls in the
      // past, or inside some active meeting's block window, would
      // otherwise silently produce an invalid scheduledAt — bump forward
      // past whichever (possibly chained) restriction applies.
      if (_isPastDateTime(_selectedDate, _selectedTime)) {
        final adjusted = _nextAvailableSlot(DateTime.now());
        _selectedDate = DateTime(adjusted.year, adjusted.month, adjusted.day);
        _selectedTime = TimeOfDay(hour: adjusted.hour, minute: adjusted.minute);
      } else if (_isWithinActiveMeetingBlock(_selectedDate, _selectedTime)) {
        final combined = DateTime(_selectedDate.year, _selectedDate.month,
            _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
        final adjusted = _nextAvailableSlot(combined);
        _selectedDate = DateTime(adjusted.year, adjusted.month, adjusted.day);
        _selectedTime = TimeOfDay(hour: adjusted.hour, minute: adjusted.minute);
      }
    });
  }

  // Native showTimePicker has no way to disable individual times, so a
  // past time (today) or one inside an active meeting's own 15-minute
  // block window could only be caught after the fact. This opens a slot
  // grid instead, where every disabled slot simply can't be tapped.
  Future<void> _pickTime() async {
    final picked = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TimeSlotSheet(
        date: _selectedDate,
        selectedTime: _selectedTime,
        activeMeetings: _activeMeetings,
      ),
    );
    if (picked == null) return;
    setState(() => _selectedTime = picked);
  }

  void _submit() {
    final partnerId = _partnerId;
    final baseLocation = _locationCtrl.text.trim();

    if (partnerId == null || partnerId.isEmpty) {
      AppSnackbar.info(context, 'Select who you\'re meeting with first.');
      return;
    }
    if (baseLocation.isEmpty) {
      AppSnackbar.info(context, 'Location is required.');
      return;
    }

    // Prepend flat/floor and building details, if given, to the map/typed
    // address so the backend still just receives one formatted string.
    final location = [
      _floorFlatCtrl.text.trim(),
      _buildingNameCtrl.text.trim(),
      baseLocation,
    ].where((s) => s.isNotEmpty).join(', ');

    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Only check if it's in the past.
    if (_isDisabledDateTime(_selectedDate, _selectedTime)) {
      AppSnackbar.info(context, 'Please choose a current or future time.');
      return;
    }

    context.read<MeetingsBloc>().add(
          MeetingScheduleRequested(
            partnerId: partnerId,
            scheduledAt: scheduledAt,
            purpose: _selectedPurpose,
            location: location,
            latitude: _pickedLatitude,
            longitude: _pickedLongitude,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: BlocConsumer<MeetingsBloc, MeetingsState>(
        listener: (context, state) {
          if (state is MeetingScheduled) {
            AppSnackbar.success(context, 'Meeting created successfully.');
            // You're the host of a newly scheduled meeting, so it lands in
            // "Upcoming" (pending the guest's approval) — not "Requests",
            // which only lists incoming requests where you're the guest.
            context.go('${AppRoutes.meetings}?tab=upcoming');
          } else if (state is MeetingsError) {
            AppSnackbar.info(context, state.message);
          }
        },
        builder: (context, state) {
          final isSubmitting = state is MeetingsLoading;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DarkScreenHeader(title: 'Create Meeting'),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, 24, 20, context.bottomSafePadding(32)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_activeMeetings.isNotEmpty) ...[
                        const _ActiveMeetingBanner(message: _activeMeetingMessage),
                        const SizedBox(height: 20),
                      ],
                      _Label('MEETING WITH'),
                      const SizedBox(height: 10),
                      _PartnerCard(
                        partner: _selectedPartner,
                        partnerId: widget.partnerId,
                        onTap: _pickPartner,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _Label('DATE')),
                          const SizedBox(width: 12),
                          Expanded(child: _Label('TIME')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _PickerField(
                              icon: Icons.calendar_today_outlined,
                              label: DateFormat('MMM d, y').format(_selectedDate),
                              // Disabled until the active-meeting check
                              // resolves — otherwise a date/time picked in
                              // that window could dodge the block entirely,
                              // since _activeMeetings would still be empty.
                              onTap: _checkingActiveMeeting ? null : _pickDate,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PickerField(
                              icon: Icons.access_time,
                              label: _selectedTime.format(context),
                              onTap: _checkingActiveMeeting ? null : _pickTime,
                            ),
                          ),
                        ],
                      ),
                      if (_checkingActiveMeeting) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Checking your schedule…',
                          style: GoogleFonts.inter(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      const _Label('MEETING PURPOSE'),
                      const SizedBox(height: 8),
                      GridView.count(
                        padding: EdgeInsets.zero,
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.5,
                        children: _purposes.map((p) {
                          final active = p.$1 == _selectedPurpose;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedPurpose = p.$1),
                            child: Container(
                              decoration: BoxDecoration(
                                color: active ? AppColors.warning.withOpacity(0.1) : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: active ? AppColors.warning : AppColors.border,
                                  width: active ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(p.$2, style: const TextStyle(fontSize: 20)),
                                  const SizedBox(height: 6),
                                  Text(
                                    p.$1.label,
                                    style: GoogleFonts.inter(
                                      color: active ? AppColors.warning : AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: _pickLocationOnMap,
                        child: AbsorbPointer(
                          child: FieldInput(
                            label: 'Location',
                            hint: 'Tap to select location on map',
                            controller: _locationCtrl,
                            readOnly: true,
                            suffixWidget: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(
                                Icons.location_on_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FieldInput(
                        label: 'Building Name (Optional)',
                        hint: 'e.g. Sunrise Apartments',
                        controller: _buildingNameCtrl,
                        prefixIcon: Icons.apartment_outlined,
                      ),
                      const SizedBox(height: 14),
                      FieldInput(
                        label: 'Floor / Flat Number (Optional)',
                        hint: 'e.g. 4th Floor, 402',
                        controller: _floorFlatCtrl,
                        prefixIcon: Icons.door_front_door_outlined,
                      ),
                      const SizedBox(height: 20),
                      _Label('NOTES (OPTIONAL)'),
                      const SizedBox(height: 10),
                      _NotesField(controller: _notesCtrl),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: isSubmitting ? 'Creating…' : 'Create Safe Meeting',
                        // Also blocked while _checkingActiveMeeting, for the
                        // same reason the pickers are — closes the window
                        // where a slot could be submitted before the active-
                        // meeting check has had a chance to restrict it.
                        onPressed: isSubmitting || _checkingActiveMeeting ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Shown when the meeting history API (GET /v1/meetings) already has a
// `scheduled` or `pending_approval` meeting for this user — explains why
// the date/time pickers below won't accept a slot inside the 15-minute
// buffer after that meeting's start.
class _ActiveMeetingBanner extends StatelessWidget {
  final String message;
  const _ActiveMeetingBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final MemberEntity? partner;
  final String? partnerId;
  final VoidCallback onTap;
  const _PartnerCard({this.partner, this.partnerId, required this.onTap});

  // Mirrors the level naming ('none'/'low'/'medium'/'high') the API returns
  // and every other verification-level display in the app (settings,
  // profile, home) already switches on — just abbreviated to fit this
  // compact inline badge.
  static const _levelLabels = {'low': 'L1', 'medium': 'L2', 'high': 'L3'};

  @override
  Widget build(BuildContext context) {
    final hasPartner = partner != null;
    final isVerified = hasPartner && partner!.verificationLevel != 'none';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hasPartner ? AppColors.border : AppColors.warning),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: Color(0xFFDCEBFF), shape: BoxShape.circle),
              child: Center(
                child: Text(
                  hasPartner ? partner!.initials : '?',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasPartner ? partner!.name : (partnerId ?? 'No member selected'),
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  if (hasPartner) ...[
                    const SizedBox(height: 2),
                    Text(
                      'SAFEE PIN: ${partner!.safeePIN}',
                      style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isVerified ? Icons.verified : Icons.shield_outlined,
                          color: isVerified ? AppColors.blue : AppColors.textTertiary,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isVerified
                              ? '${_levelLabels[partner!.verificationLevel] ?? partner!.verificationLevel.toUpperCase()} Verified'
                              : 'Unverified',
                          style: TextStyle(
                            color: isVerified ? AppColors.blue : AppColors.textTertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Text(
              hasPartner ? 'Change' : 'Select',
              style: GoogleFonts.inter(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _PickerField({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textTertiary, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Bottom-sheet grid of selectable times, in `_slotMinutes` increments across
// [date]. A slot is disabled — rendered greyed out and untappable — only
// when it's already in the past, or when it falls inside any one of
// [activeMeetings]' own block windows (each [scheduledAt] inclusive,
// [scheduledAt]+15min exclusive — exactly Block Until is the first
// bookable slot). Each meeting is its own narrow exclusion, not a floor:
// slots earlier or later the same day, clear of every window, stay
// selectable — even between two back-to-back meetings.
class _TimeSlotSheet extends StatelessWidget {
  final DateTime date;
  final TimeOfDay selectedTime;
  final List<MeetingEntity> activeMeetings;
  const _TimeSlotSheet({
    required this.date,
    required this.selectedTime,
    this.activeMeetings = const [],
  });

  static const _crossAxisCount = 4;
  static const _rowExtent = 54.0; // mainAxisExtent (44) + mainAxisSpacing (10)

  bool _isDisabled(TimeOfDay t) {
    final combined = DateTime(date.year, date.month, date.day, t.hour, t.minute);
    if (combined.isBefore(DateTime.now())) return true;
    for (final m in activeMeetings) {
      final start = m.scheduledAt;
      final end = start.add(const Duration(minutes: 15));
      if (!combined.isBefore(start) && combined.isBefore(end)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final slots = List.generate(
      (24 * 60) ~/ _slotMinutes,
      (i) => TimeOfDay(hour: (i * _slotMinutes) ~/ 60, minute: (i * _slotMinutes) % 60),
    );

    // Scroll so the currently-selected slot (or, failing that, the first
    // enabled one) starts a couple of rows down from the top instead of
    // requiring the user to scroll from midnight every time.
    var initialIndex = slots.indexWhere(
      (t) => !_isDisabled(t) && t.hour == selectedTime.hour && t.minute == selectedTime.minute,
    );
    if (initialIndex == -1) initialIndex = slots.indexWhere((t) => !_isDisabled(t));
    final rowIndex = initialIndex < 0 ? 0 : initialIndex ~/ _crossAxisCount;
    final scrollController = ScrollController(
      initialScrollOffset: (rowIndex * _rowExtent - _rowExtent * 2).clamp(0, double.infinity),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Time',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _crossAxisCount,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 44,
                  ),
                  itemCount: slots.length,
                  itemBuilder: (context, i) {
                    final slot = slots[i];
                    final disabled = _isDisabled(slot);
                    final isSelected = !disabled &&
                        slot.hour == selectedTime.hour &&
                        slot.minute == selectedTime.minute;
                    return GestureDetector(
                      onTap: disabled ? null : () => Navigator.of(context).pop(slot),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : disabled
                                  ? AppColors.lightBg
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Text(
                          slot.format(context),
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : disabled
                                    ? AppColors.textTertiary.withOpacity(0.5)
                                    : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotesField extends StatelessWidget {
  final TextEditingController controller;
  const _NotesField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        maxLines: 4,
        minLines: 4,
        style: TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Add any notes or instructions…',
          hintStyle: TextStyle(color: AppColors.textTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}

