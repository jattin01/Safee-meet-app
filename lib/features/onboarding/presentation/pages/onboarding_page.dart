import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/dependency_injection/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../core/shared/widgets/primary_button.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _current = 0;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _slides = [
    _OnboardingSlide(
      title: 'Meet Safely',
      tagline: 'EVERY CONNECTION VERIFIED',
      subtitle:
          "Know exactly who you're meeting before you step out the door. SAFEE MEET gives you the confidence to meet with complete peace of mind.",
      accentColor: AppColors.primary,
      illustration: _IllustrationType.logo,
    ),
    _OnboardingSlide(
      title: 'Verify Identity',
      tagline: 'TRUST, NOT ASSUMPTION',
      subtitle:
          'Multi-layer identity verification including National ID, facial recognition, and background screening. Real identity. Real trust.',
      accentColor: AppColors.blue,
      illustration: _IllustrationType.identity,
    ),
    _OnboardingSlide(
      title: 'Stay Protected',
      tagline: 'SAFETY AT EVERY STEP',
      subtitle:
          'Live location sharing, trusted contact alerts, and one-tap SOS emergency protection keep you safe throughout every meeting.',
      accentColor: AppColors.success,
      illustration: _IllustrationType.map,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _goToSlide(int index) {
    _animCtrl.forward(from: 0);
    _pageCtrl.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    setState(() => _current = index);
  }

  void _skip() => _completeOnboarding();

  void _next() {
    if (_current < _slides.length - 1) {
      _goToSlide(_current + 1);
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    await sl<HiveService>().setOnboarded();
    if (mounted) context.go(AppRoutes.auth);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _current == _slides.length - 1;
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 24, 0),
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) {
                  _animCtrl.forward(from: 0);
                  setState(() => _current = i);
                },
                itemCount: _slides.length,
                itemBuilder: (_, i) => FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: _SlideView(
                      slide: _slides[i],
                      index: i,
                      currentIndex: _current,
                      total: _slides.length,
                      onDotTap: _goToSlide,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: PrimaryButton(
                label: isLast ? 'Get Started' : 'Continue',
                onPressed: _next,
                icon: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _IllustrationType { logo, identity, map }

class _OnboardingSlide {
  final String title;
  final String tagline;
  final String subtitle;
  final Color accentColor;
  final _IllustrationType illustration;

  const _OnboardingSlide({
    required this.title,
    required this.tagline,
    required this.subtitle,
    required this.accentColor,
    required this.illustration,
  });
}

class _SlideView extends StatelessWidget {
  final _OnboardingSlide slide;
  final int index;
  final int currentIndex;
  final int total;
  final ValueChanged<int> onDotTap;

  const _SlideView({
    required this.slide,
    required this.index,
    required this.currentIndex,
    required this.total,
    required this.onDotTap,
  });

  Widget get _illustration {
    switch (slide.illustration) {
      case _IllustrationType.logo:
        return const _LogoIllustration();
      case _IllustrationType.identity:
        return const _IdentityIllustration();
      case _IllustrationType.map:
        return const _MapIllustration();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _illustration,
          const SizedBox(height: 80),
          Row(
            children: List.generate(total, (i) {
              final isActive = i == currentIndex;
              return GestureDetector(
                onTap: () => onDotTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 8),
                  width: isActive ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? slide.accentColor : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Text(
            slide.title,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            slide.tagline,
            style: GoogleFonts.inter(
              color: slide.accentColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.subtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Slide 1 illustration: brand logo lockup in a white card ────────────────
class _LogoIllustration extends StatelessWidget {
  const _LogoIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 310,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/brand_logo_icon.png', width: 90, fit: BoxFit.contain),
          const SizedBox(height: 18),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'SAFEE ',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'MEET',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 1.5,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Are you verified?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 18,
                height: 1.5,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Slide 2 illustration: identity card mock ────────────────────────────
class _IdentityIllustration extends StatelessWidget {
  const _IdentityIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 310,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft glow behind the card
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.blue.withOpacity(0.12), AppColors.blue.withOpacity(0.0)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar placeholder (dashed circle)
                CustomPaint(
                  painter: _DashedCirclePainter(color: AppColors.blue.withOpacity(0.5)),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(Icons.person_outline, color: AppColors.blue.withOpacity(0.6), size: 26),
                  ),
                ),
                const SizedBox(height: 4),
                // ID card
                Container(
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            color: AppColors.blue,
                            child: Text(
                              'IDENTITY CARD',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.blue.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.person, color: AppColors.blue, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _Bar(width: 70),
                                      const SizedBox(height: 6),
                                      _Bar(width: 100),
                                      const SizedBox(height: 6),
                                      _Bar(width: 60),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        right: 8,
                        top: 22,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double width;
  const _Bar({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const dashCount = 18;
    const sweep = (2 * math.pi) / dashCount * 0.6;
    const gap = (2 * math.pi) / dashCount * 0.4;
    double angle = 0;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,
        sweep,
        false,
        paint,
      );
      angle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Slide 3 illustration: live-tracking / SOS map mock ──────────────────
class _MapIllustration extends StatelessWidget {
  const _MapIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 310,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.success.withOpacity(0.12), AppColors.success.withOpacity(0.0)],
              ),
            ),
          ),
          Container(
            width: 230,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _MapMockPainter())),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'SOS',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border.withOpacity(0.6)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final start = Offset(size.width * 0.22, size.height * 0.82);
    final end = Offset(size.width * 0.82, size.height * 0.22);
    final mid = Offset.lerp(start, end, 0.55)!;

    // Dashed route line
    final routePaint = Paint()
      ..color = AppColors.success
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    const dashLen = 6.0, gapLen = 5.0;
    final total = (end - start).distance;
    final dir = (end - start) / total;
    double covered = 0;
    while (covered < total) {
      final segEnd = math.min(covered + dashLen, total);
      canvas.drawLine(start + dir * covered, start + dir * segEnd, routePaint);
      covered += dashLen + gapLen;
    }

    // Start marker (red ring)
    canvas.drawCircle(
      start,
      7,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(start, 7, Paint()..color = Colors.white);
    canvas.drawCircle(
      start,
      7,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // End marker (solid green)
    canvas.drawCircle(end, 7, Paint()..color = AppColors.success);
    canvas.drawCircle(end, 7, Paint()..color = Colors.white.withOpacity(0.0));

    // Live location pulse (blue) at the midpoint
    canvas.drawCircle(mid, 14, Paint()..color = AppColors.blue.withOpacity(0.15));
    canvas.drawCircle(mid, 9, Paint()..color = AppColors.blue.withOpacity(0.25));
    canvas.drawCircle(mid, 5, Paint()..color = AppColors.blue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
