import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_colors.dart';
import '../bloc/sos_bloc.dart';

class SosPage extends StatefulWidget {
  final String? meetingId;
  const SosPage({super.key, this.meetingId});

  @override
  State<SosPage> createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    context.read<SosBloc>().add(const SosLoadRequested());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SosBloc, SosState>(
      listener: (context, state) {
        if (state is SosDone) context.pop();
      },
      builder: (context, state) {
        final activated = state is SosActivatedState;
        return Scaffold(
          backgroundColor: activated ? const Color(0xFF1A0508) : AppColors.darkBg,
          body: SafeArea(
            child: activated
                ? _ActivatedView(
                    state: state,
                    onCancel: () =>
                        context.read<SosBloc>().add(const SosCancelled()),
                  )
                : _IdleView(
                    progress: state is SosHolding ? state.progress : 0.0,
                    contactCount: state is SosInitial ? state.contacts.length : 0,
                    pulseAnim: _pulseAnim,
                    onHoldStart: () => context
                        .read<SosBloc>()
                        .add(SosHoldStarted(meetingId: widget.meetingId)),
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
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          Expanded(
            child: Text(
              'Emergency SOS',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
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
          style: GoogleFonts.inter(color: Colors.white, fontSize: size * 0.28, fontWeight: FontWeight.w800),
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
    return Column(
      children: [
        const _TopBar(),
        const SizedBox(height: 60),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Hold the button below to activate emergency alert',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ),
        const SizedBox(height: 56),
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
                  border: Border.all(color: AppColors.primary, width: 3),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withOpacity(0.6), blurRadius: 40, spreadRadius: 4),
                  ],
                ),
              ),
              ScaleTransition(
                scale: progress > 0 ? const AlwaysStoppedAnimation(1.0) : pulseAnim,
                child: GestureDetector(
                  onLongPressStart: (_) => onHoldStart(),
                  onLongPressEnd: (_) => onHoldEnd(),
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [AppColors.primaryLight, AppColors.primary],
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
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, letterSpacing: 2),
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
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 48),
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
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoRow({required this.icon, required this.title, required this.subtitle});

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
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.18), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primaryLight, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
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
        const _TopBar(),
        const SizedBox(height: 40),
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [AppColors.primaryLight, AppColors.primary]),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withOpacity(0.6), blurRadius: 50, spreadRadius: 6),
            ],
          ),
          child: const Center(child: _SosBadge(size: 44)),
        ),
        const SizedBox(height: 24),
        Text(
          'SOS ACTIVATED',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.5),
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
                style: GoogleFonts.inter(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w700),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'No trusted contacts on file yet.',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  )
                else
                  ...state.contacts.map((c) => _ContactRow(contact: c)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.white70, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _locationLabel,
                          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text('Sharing', style: GoogleFonts.inter(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24, top: 8),
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
                  Text('Cancel SOS', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
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
            contact.notified ? Icons.check_circle : Icons.radio_button_unchecked,
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
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(contact.phone, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              Text(contact.notified ? 'Notified' : 'Pending', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(width: 4),
              Icon(contact.notified ? Icons.check : Icons.schedule, color: Colors.white70, size: 14),
            ],
          ),
        ],
      ),
    );
  }
}
