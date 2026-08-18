import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/shared/utils/feature_gate.dart';
import '../../../../core/shared/utils/safe_bottom_padding.dart';
import '../bloc/sos_bloc.dart';
import 'package:safee_meet/core/shared/widgets/app_snackbar.dart';

class SosPage extends StatefulWidget {
  final String? meetingId;
  const SosPage({super.key, this.meetingId});

  @override
  State<SosPage> createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Persisted here rather than re-derived from `state` on every build:
  // SosHolding/SosActivatedState/SosDone carry no contacts info of their
  // own, so a naive switch would read as "0 contacts" while holding the
  // button or once activated — flashing the "No trusted contacts" subtitle
  // on and off for users who actually have contacts. Only
  // SosInitial/SosError ever update this; every other state leaves it as
  // whatever was last known.
  int _contactCount = 0;

  // Shows the "No Emergency Contact Added" sheet at most once per visit to
  // this page — otherwise every SosInitial re-emission with zero contacts
  // (e.g. releasing an early hold) would pop it open again.
  bool _contactSheetShown = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.1)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    context.read<SosBloc>().add(const SosLoadRequested());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _showNoContactSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NoEmergencyContactSheet(
        onAddContact: () {
          Navigator.of(context).pop();
          context.push(AppRoutes.emergencyContacts);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SosBloc, SosState>(
      listener: (context, state) {
        // SosPage can be pushed from several places (the persistent shell
        // SOS button, Home, or an active meeting's Live Location screen) —
        // context.pop() used to just return to whichever of those launched
        // it, so triggering SOS during a meeting landed back on Live
        // Location. Go to Home explicitly instead, regardless of entry
        // point.
        if (state is SosDone) context.go(AppRoutes.home);
        if (state is SosError) {
          AppSnackbar.info(context, state.message);
        }
        // Fires once, the first time we can actually confirm the account
        // has zero emergency contacts — not on the bloc's un-fetched
        // super-initial state, and not again on a later SosInitial (e.g.
        // releasing an early hold) once the sheet's already been shown.
        final justConfirmedEmpty = state is SosInitial &&
            state.contactsLoaded &&
            state.contacts.isEmpty;
        if (justConfirmedEmpty && !_contactSheetShown) {
          _contactSheetShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showNoContactSheet(context);
          });
        }
      },
      builder: (context, state) {
        if (state is SosInitial) {
          _contactCount = state.contacts.length;
        } else if (state is SosError) {
          _contactCount = state.contacts.length;
        }
        final activated = state is SosActivatedState;
        return Scaffold(
          backgroundColor:
              activated ? const Color(0xFF1A0508) : AppColors.darkBg,
          body: SafeArea(
            child: activated
                ? _ActivatedView(
                    state: state,
                    onCancel: () =>
                        context.read<SosBloc>().add(const SosCancelled()),
                  )
                : _IdleView(
                    progress: state is SosHolding ? state.progress : 0.0,
                    contactCount: _contactCount,
                    pulseAnim: _pulseAnim,
                    // Gated here, at the actual trigger, rather than at the
                    // entry points that push this page (shell SOS button,
                    // Home's Emergency SOS tile) — the page itself always
                    // opens, but holding the button to really activate SOS
                    // requires Trusted Contact Alerts on the current plan.
                    onHoldStart: () {
                      if (!requireFeature(
                        context,
                        PlanFeature.trustedContactAlerts,
                        'Trusted Contact Alerts',
                      )) {
                        return;
                      }
                      context
                          .read<SosBloc>()
                          .add(SosHoldStarted(meetingId: widget.meetingId));
                    },
                    onHoldEnd: () =>
                        context.read<SosBloc>().add(const SosHoldReleased()),
                  ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  // Idle (SOS not yet triggered): defaults to a plain pop, back to
  // whichever screen launched this one — nothing was created, so there's
  // nothing to redirect around.
  // Activated (SOS already triggered successfully): the SosDone listener
  // in SosPage already sends "Cancel SOS" to Home instead of back to
  // whatever launched this screen (e.g. Live Location) — but the back
  // arrow is a second, separate exit that bypassed that entirely via a
  // bare context.pop(). _ActivatedView passes an explicit onBack here so
  // both exits land in the same place once an SOS has actually gone out.
  final VoidCallback? onBack;
  const _TopBar({this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack ?? () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle),
              child:
                  const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          Expanded(
            child: Text(
              'Emergency SOS',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _SosBadge extends StatelessWidget {
  final double size;
  const _SosBadge({this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.warning, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Center(
        child: Text(
          'SOS',
          style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: size * 0.28,
              fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  final double progress;
  final int contactCount;
  final Animation<double> pulseAnim;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  const _IdleView({
    required this.progress,
    required this.contactCount,
    required this.pulseAnim,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const _TopBar(),
                  const Spacer(flex: 3),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Hold the button below to activate emergency alert',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 15),
                    ),
                  ),
                  const Spacer(flex: 3),
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow ring
                        Container(
                          width: 230,
                          height: 230,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppColors.primary, width: 3),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.primary.withOpacity(0.6),
                                  blurRadius: 40,
                                  spreadRadius: 4),
                            ],
                          ),
                        ),
                        ScaleTransition(
                          scale: progress > 0
                              ? const AlwaysStoppedAnimation(1.0)
                              : pulseAnim,
                          child: GestureDetector(
                            onLongPressStart: (_) => onHoldStart(),
                            onLongPressEnd: (_) => onHoldEnd(),
                            child: Container(
                              width: 190,
                              height: 190,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.primaryLight,
                                    AppColors.primary
                                  ],
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const _SosBadge(),
                                  const SizedBox(height: 10),
                                  Text(
                                    'SOS',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'HOLD',
                                    style: GoogleFonts.inter(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        letterSpacing: 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (progress > 0)
                          SizedBox(
                            width: 230,
                            height: 230,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 4,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const _InfoRow(
                          icon: Icons.location_on,
                          title: 'GPS Location Shared',
                          subtitle: 'Real-time location sent to contacts',
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.phone_in_talk,
                          title: 'Emergency Contacts Alerted',
                          subtitle: contactCount > 0
                              ? '$contactCount trusted contact${contactCount == 1 ? '' : 's'} will be notified instantly'
                              : 'No trusted contacts on file yet',
                        ),
                        const SizedBox(height: 12),
                        const _InfoRow(
                          icon: Icons.check_circle_outline,
                          title: 'Incident Report Created',
                          subtitle: 'Timestamped record automatically saved',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Bottom sheet shown once per SOS-page visit when the account has zero
// emergency contacts on file — nudges the user to add one without
// blocking the SOS button itself (holding it still works with no
// contacts; the backend/UI elsewhere is whatever already restricts that,
// if anything does). Matches the Figma bottom-sheet reference: dark card,
// drag handle + close button, centered warning badge, title/subtitle,
// three feature rows, a gradient CTA, and a "Remind me later" dismiss.
class _NoEmergencyContactSheet extends StatelessWidget {
  final VoidCallback onAddContact;
  const _NoEmergencyContactSheet({required this.onAddContact});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        // Caps how tall the sheet can grow on a short/landscape viewport —
        // the scroll view inside then takes over instead of overflowing.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.darkBg2,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      24, 14, 24, context.bottomSafePadding(24)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Center(child: _AlertBadge()),
                      const SizedBox(height: 20),
                      Text(
                        'No Emergency Contact Added',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a trusted contact so someone is notified '
                        'immediately when you activate SOS.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _SheetFeatureRow(
                        icon: Icons.notifications,
                        label: 'Instant alert sent to your contact',
                      ),
                      const SizedBox(height: 12),
                      const _SheetFeatureRow(
                        icon: Icons.location_on,
                        label: 'Your GPS location shared in real-time',
                      ),
                      const SizedBox(height: 12),
                      const _SheetFeatureRow(
                        icon: Icons.access_time,
                        label: 'Timestamped incident report created',
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: onAddContact,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_add_alt_1,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Add Emergency Contact',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            'Remind me later',
                            style: GoogleFonts.inter(
                              color: AppColors.textTertiary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.white70, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertBadge extends StatefulWidget {
  const _AlertBadge();

  @override
  State<_AlertBadge> createState() => _AlertBadgeState();
}

class _AlertBadgeState extends State<_AlertBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Expanding water drop / ripple border (rounded rectangle shape)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final size = 64 + (24 * _controller.value);
              final opacity = 1.0 - _controller.value;
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18 + (10 * _controller.value)),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.5 * opacity),
                    width: 1.2,
                  ),
                ),
              );
            },
          ),
          // Inner squircle with shield
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.darkBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.warning, width: 1.5),
            ),
            child: const Icon(
              Icons.gpp_maybe_outlined,
              color: AppColors.warning,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

// One "what happens if you add a contact" row inside the sheet — a small
// squircle icon tile (tinted with the brand red, matching the CTA below)
// plus a single line of label text.
class _SheetFeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SheetFeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.16),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.primaryLight, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoRow(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.18),
                shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primaryLight, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivatedView extends StatelessWidget {
  final SosActivatedState state;
  final VoidCallback onCancel;
  const _ActivatedView({required this.state, required this.onCancel});

  String get _locationLabel {
    final lat = state.lat;
    final lng = state.lng;
    if (lat == null || lng == null) return 'Locating…';
    final latHemi = lat >= 0 ? 'N' : 'S';
    final lngHemi = lng >= 0 ? 'E' : 'W';
    return 'GPS: ${lat.abs().toStringAsFixed(4)}° $latHemi, '
        '${lng.abs().toStringAsFixed(4)}° $lngHemi';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopBar(onBack: () => context.go(AppRoutes.home)),
        const SizedBox(height: 40),
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
                colors: [AppColors.primaryLight, AppColors.primary]),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withOpacity(0.6),
                  blurRadius: 50,
                  spreadRadius: 6),
            ],
          ),
          child: const Center(child: _SosBadge(size: 44)),
        ),
        const SizedBox(height: 24),
        Text(
          'SOS ACTIVATED',
          style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5),
        ),
        const SizedBox(height: 6),
        Text(
          'Emergency alert sent to all contacts',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 16),
              const SizedBox(width: 6),
              Text(
                'Emergency services contacted',
                style: GoogleFonts.inter(
                    color: AppColors.success,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                if (state.contacts.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'No trusted contacts on file yet.',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  )
                else
                  ...state.contacts.map((c) => _ContactRow(contact: c)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: Colors.white70, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _locationLabel,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text('Sharing',
                          style: GoogleFonts.inter(
                              color: AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          // Was a bare 24 — this button sits directly above the Android
          // nav bar with nothing scrollable below it, so on devices where
          // that inset isn't fully covered by SafeArea alone it ended up
          // partly hidden/overlapped. bottomSafePadding adds the device's
          // own inset on top of the same visual gap.
          padding:
              EdgeInsets.only(bottom: context.bottomSafePadding(24), top: 8),
          child: GestureDetector(
            onTap: onCancel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.close, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text('Cancel SOS',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  final SosContactEntity contact;
  const _ContactRow({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            contact.notified
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: contact.notified ? AppColors.success : Colors.white54,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(contact.phone,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              Text(contact.notified ? 'Notified' : 'Pending',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(width: 4),
              Icon(contact.notified ? Icons.check : Icons.schedule,
                  color: Colors.white70, size: 14),
            ],
          ),
        ],
      ),
    );
  }
}
