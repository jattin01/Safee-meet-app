import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_colors.dart';

// PROTOTYPE MODE: this page renders mock data only — there is no SosBloc
// wiring or backend connectivity. Re-connect it to SosBloc (SosHoldStarted /
// SosHoldReleased / SosActivated / SosCancelled) before shipping.
class SosPage extends StatefulWidget {
  const SosPage({super.key});

  @override
  State<SosPage> createState() => _SosPageState();
}

class _Contact {
  final String name;
  final String emoji;
  const _Contact(this.name, this.emoji);
}

class _SosPageState extends State<SosPage> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  double _holdProgress = 0.0;
  bool _activated = false;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _startHold() {
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 40), (t) {
      setState(() => _holdProgress += 40 / 2000);
      if (_holdProgress >= 1.0) {
        t.cancel();
        setState(() {
          _activated = true;
          _holdProgress = 0;
        });
      }
    });
  }

  void _releaseHold() {
    _holdTimer?.cancel();
    if (!_activated) setState(() => _holdProgress = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _activated ? const Color(0xFF1A0508) : AppColors.darkBg,
      body: SafeArea(
        child: _activated ? _ActivatedView(onCancel: () => context.pop()) : _IdleView(
          progress: _holdProgress,
          pulseAnim: _pulseAnim,
          onHoldStart: _startHold,
          onHoldEnd: _releaseHold,
        ),
      ),
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
  final Animation<double> pulseAnim;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  const _IdleView({
    required this.progress,
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
            children: const [
              _InfoRow(
                icon: Icons.location_on,
                title: 'GPS Location Shared',
                subtitle: 'Real-time location sent to contacts',
              ),
              SizedBox(height: 12),
              _InfoRow(
                icon: Icons.phone_in_talk,
                title: 'Emergency Contacts Alerted',
                subtitle: '3 trusted contacts notified instantly',
              ),
              SizedBox(height: 12),
              _InfoRow(
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
  final VoidCallback onCancel;
  const _ActivatedView({required this.onCancel});

  static const _contacts = [
    _Contact('Mom', '👩'),
    _Contact('Jake', '👦'),
    _Contact('Emergency Services', '🚨'),
  ];

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
                ..._contacts.map((c) => _ContactRow(contact: c)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: AppColors.textTertiary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'GPS: 40.7589° N, 73.9851° W',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
  final _Contact contact;
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
          Icon(Icons.check_circle, color: AppColors.success, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${contact.name} ${contact.emoji}',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          Row(
            children: [
              Text('Notified', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
              const SizedBox(width: 4),
              Icon(Icons.check, color: AppColors.textTertiary, size: 14),
            ],
          ),
        ],
      ),
    );
  }
}
