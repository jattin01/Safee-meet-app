import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/dependency_injection/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../core/storage/auth_session_manager.dart';
import '../../../subscription/presentation/cubit/current_subscription_cubit.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  // Phase: 0=initial, 1=logo, 2=text, 3=done
  late AnimationController _phase1Ctrl; // logo scale+fade
  late AnimationController _phase2Ctrl; // text fade
  late AnimationController _glowCtrl; // soft breathing glow behind the shield

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _glowOpacity;

  int _dotIndex = 0;
  Timer? _dotTimer;

  @override
  void initState() {
    super.initState();

    _dotTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (mounted) {
        setState(() => _dotIndex = (_dotIndex + 1) % 3);
      }
    });

    _phase1Ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _phase2Ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _phase1Ctrl, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _phase1Ctrl, curve: const Interval(0, 0.5)));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _phase2Ctrl, curve: Curves.easeIn));
    _glowOpacity = Tween<double>(begin: 0.35, end: 0.6)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _phase1Ctrl.forward();
    await Future.delayed(const Duration(milliseconds: 700));
    _phase2Ctrl.forward();
    // Total 3300ms per source spec (3.3s auto-advance)
    await Future.delayed(const Duration(milliseconds: 2400));
    if (mounted) _navigate();
  }

  Future<void> _navigate() async {
    final hive    = sl<HiveService>();
    final session = sl<AuthSessionManager>();

    final onboarded = hive.isOnboarded;
    final authed    = await session.isAuthenticated();

    if (authed) {
      // Warm the current-plan cache as early as possible so it's already
      // loaded (or loading) by the time the dashboard/shell mounts —
      // fire-and-forget, cache-aware (15-min TTL) and safe to call again
      // from the router guard/shell without duplicating work.
      unawaited(sl<CurrentSubscriptionCubit>().load());
    }

    if (!mounted) return;
    if (!onboarded) {
      context.go(AppRoutes.onboarding);
    } else if (authed) {
      context.go(AppRoutes.dashboardHome);
    } else {
      context.go(AppRoutes.auth);
    }
  }

  @override
  void dispose() {
    _dotTimer?.cancel();
    _phase1Ctrl.dispose();
    _phase2Ctrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [Color(0xFF1A0A0F), AppColors.darkBg],
              ),
            ),
          ),
          // Soft breathing glow behind the shield
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, __) => Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(_glowOpacity.value * 0.22),
                    AppColors.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Logo lockup: shield + wordmark + tagline
          AnimatedBuilder(
            animation: Listenable.merge([_phase1Ctrl, _phase2Ctrl]),
            builder: (_, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: _logoScale.value,
                  child: Opacity(
                    opacity: _logoOpacity.value,
                    child: Image.asset(
                      'assets/images/brand_logo_icon.png',
                      width: 110,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Opacity(
                  opacity: _textOpacity.value,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'SAFEE ',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.3,
                        ),
                      ),
                      Text(
                        'MEET',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Opacity(
                  opacity: _textOpacity.value,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
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
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 20,
                        height: 1.5,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Pagination dots at the bottom
          Positioned(
            bottom: 60,
            child: AnimatedBuilder(
              animation: _phase2Ctrl,
              builder: (_, __) => Opacity(
                opacity: _textOpacity.value,
                child: _PaginationDots(activeIndex: _dotIndex, count: 3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationDots extends StatelessWidget {
  final int activeIndex;
  final int count;

  const _PaginationDots({required this.activeIndex, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == activeIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}
