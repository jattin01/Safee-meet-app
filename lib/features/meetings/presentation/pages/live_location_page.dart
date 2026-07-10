import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/routes/app_routes.dart';

class LiveLocationPage extends StatefulWidget {
  const LiveLocationPage({super.key});

  @override
  State<LiveLocationPage> createState() => _LiveLocationPageState();
}

class _LiveLocationPageState extends State<LiveLocationPage> {
  Timer? _timer;
  Duration _elapsed = const Duration(minutes: 12, seconds: 34);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showEndDialog() {
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
              context.go(AppRoutes.home);
            },
            child: Text('End Meeting', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = _elapsed.inHours.toString().padLeft(2, '0');
    final m = (_elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _Header(elapsed: '$h:$m:$s'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MeetingProgressCard(),
                  const SizedBox(height: 16),
                  _TrustedContactsCard(),
                  const SizedBox(height: 16),
                  _LiveLocationCard(),
                  const SizedBox(height: 16),
                  _ActionButtons(onSos: () => context.push(AppRoutes.sos)),
                  const SizedBox(height: 16),
                  _EndMeetingButton(onTap: _showEndDialog),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dark top header (appbar + meeting card + map) ──────────────────────────

class _Header extends StatelessWidget {
  final String elapsed;
  const _Header({required this.elapsed});

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
                _LiveBadge(),
              ],
            ),
          ),

          // Meeting partner card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _PartnerCard(),
          ),
          const SizedBox(height: 12),

          // Map placeholder with overlays
          _MapSection(elapsed: elapsed),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkBg2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.blue,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('👩', style: TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sarah Mitchell',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Text('☕', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Coffee Meeting · Jun 14, 2:00 PM',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'On time',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '2 min away',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapSection extends StatelessWidget {
  final String elapsed;
  const _MapSection({required this.elapsed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          // Map placeholder
          const _MapPlaceholder(),

          // Timer badge (top-left)
          Positioned(
            top: 14,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.darkBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    elapsed,
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

          // Distance badge (bottom-right)
          Positioned(
            bottom: 14,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.darkBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.navigation, color: AppColors.success, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    '0.4 mi away',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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

    // Current location dot (blue with white ring)
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(startX, midY), 10, dotPaint);
    final innerDotPaint = Paint()..color = const Color(0xFF3B82F6);
    canvas.drawCircle(Offset(startX, midY), 7, innerDotPaint);

    // Destination pin (red)
    final pinPaint = Paint()..color = const Color(0xFFEF4444);
    final pinPath = Path();
    final px = endX;
    final py = midY;
    pinPath.moveTo(px, py + 14);
    pinPath.quadraticBezierTo(px - 12, py + 2, px - 12, py - 6);
    pinPath.arcToPoint(Offset(px + 12, py - 6),
        radius: const Radius.circular(12), clockwise: false);
    pinPath.quadraticBezierTo(px + 12, py + 2, px, py + 14);
    pinPath.close();
    canvas.drawPath(pinPath, pinPaint);
    canvas.drawCircle(Offset(px, py - 6), 4, Paint()..color = Colors.white);
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
      (label: 'Done', number: 4, done: false, active: false),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
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
          const SizedBox(height: 18),
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

class _TrustedContactsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const contacts = [
      (name: 'Mom', emoji: '👩'),
      (name: 'Jake', emoji: '👦'),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_outline, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              Text(
                'Trusted Contacts Notified',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: contacts
                .map((c) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              c.name,
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(c.emoji, style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Live Location ───────────────────────────────────────────────────────────

class _LiveLocationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: AppColors.blue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live Location Active',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '40.7589° N, 73.9851° W',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sharing',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Action Buttons ──────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final VoidCallback onSos;
  const _ActionButtons({required this.onSos});

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
            onTap: () {},
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
        padding: const EdgeInsets.symmetric(vertical: 18),
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
  final VoidCallback onTap;
  const _EndMeetingButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
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
