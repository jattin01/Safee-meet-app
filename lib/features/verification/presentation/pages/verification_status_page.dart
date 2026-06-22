import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';

// PROTOTYPE MODE: this page renders mock data only — there is no
// VerificationBloc wiring or backend connectivity. Re-connect it to
// VerificationStatusRequested before shipping.
class VerificationStatusPage extends StatelessWidget {
  const VerificationStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DarkScreenHeader(
              title: 'Verification Status',
              titleFontSize: 21,
              childGap: 20,
              child: _TrustScoreCard(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  _LevelCard(
                    icon: Icons.shield,
                    color: AppColors.success,
                    title: 'Level 1 Verification',
                    statusEmoji: '✅',
                    statusText: 'Verified',
                    badgeLabel: 'Verified',
                    badgeColor: AppColors.success,
                    items: [
                      _CheckItem('Driver License Uploaded', done: true),
                      _CheckItem('OCR Data Extraction', done: true),
                      _CheckItem('Face Match Confirmed', done: true),
                      _CheckItem('Liveness Detection', done: true),
                    ],
                  ),
                  SizedBox(height: 16),
                  _LevelCard(
                    icon: Icons.shield,
                    color: AppColors.blue,
                    title: 'Level 2 Verification',
                    statusEmoji: '✅',
                    statusText: 'Verified',
                    badgeLabel: 'Premium',
                    badgeColor: AppColors.warning,
                    items: [
                      _CheckItem('Background Screening', done: true),
                      _CheckItem('Criminal Record Check', done: true),
                      _CheckItem('Address Validation', done: true),
                      _CheckItem('Identity Cross-Reference', done: true),
                    ],
                  ),
                  SizedBox(height: 16),
                  _ProfessionalCard(),
                  SizedBox(height: 20),
                  _SafetyScoreBreakdown(),
                  SizedBox(height: 24),
                  _MemberReviews(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustScoreCard extends StatelessWidget {
  const _TrustScoreCard();

  static const _score = 94;
  static const _name = 'Alex Johnson';
  static const _memberSince = 'May 2024';
  static const _pin = '#SM-7821';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.darkBg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _score / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_score',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'TRUST SCORE',
                      style: GoogleFonts.inter(
                        color: AppColors.textTertiary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(_name, style: GoogleFonts.inter(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Member since $_memberSince · PIN $_pin',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MiniBadge(emoji: '🟢', label: 'Level 1', color: AppColors.success),
              const SizedBox(width: 10),
              _MiniBadge(emoji: '🔵', label: 'Level 2', color: AppColors.blue),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  const _MiniBadge({required this.emoji, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CheckItem {
  final String text;
  final bool done;
  const _CheckItem(this.text, {required this.done});
}

class _LevelCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String statusEmoji;
  final String statusText;
  final String badgeLabel;
  final Color badgeColor;
  final List<_CheckItem> items;

  const _LevelCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.statusEmoji,
    required this.statusText,
    required this.badgeLabel,
    required this.badgeColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text('$statusEmoji $statusText',
                          style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeLabel,
                    style: GoogleFonts.inter(color: badgeColor, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderLight),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: items
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: AppColors.success, size: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(item.text,
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ),
                            Icon(Icons.check, color: AppColors.success, size: 16),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  const _ProfessionalCard();

  static const _items = ['Business License Upload', 'Credential Verification', 'Insurance Verification'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
                  child: const Icon(Icons.shield, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Professional Verification',
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text('⏳ Pending',
                          style: TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Pro',
                    style: GoogleFonts.inter(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderLight),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              children: _items
                  .map((text) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, color: AppColors.warning, size: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(text, style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          Divider(height: 1, color: AppColors.borderLight),
          GestureDetector(
            onTap: () => context.push(AppRoutes.subscription),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Complete Verification',
                    style: GoogleFonts.inter(color: AppColors.warning, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right, color: AppColors.warning, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyScoreBreakdown extends StatelessWidget {
  const _SafetyScoreBreakdown();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Safety Score Breakdown',
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          _ScoreBar(label: 'Identity Verification', value: 1.0, color: AppColors.success),
          const SizedBox(height: 16),
          _ScoreBar(label: 'Meeting Safety', value: 0.96, color: AppColors.blue),
          const SizedBox(height: 16),
          _ScoreBar(label: 'Response Rate', value: 0.88, color: AppColors.purple),
          const SizedBox(height: 16),
          _ScoreBar(label: 'Trust Score', value: 0.94, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _ScoreBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Text('${(value * 100).toInt()}%',
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: AppColors.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 7,
          ),
        ),
      ],
    );
  }
}

class _MemberReviews extends StatelessWidget {
  const _MemberReviews();

  static const _reviews = [
    _ReviewMock(
      emoji: '😊',
      bg: Color(0xFFDCEBFF),
      name: 'Sarah M.',
      rating: 5,
      date: 'Jun 9',
      text: 'Alex was incredibly professional and trustworthy. Felt completely safe during our meeting.',
    ),
    _ReviewMock(
      emoji: '🧑',
      bg: Color(0xFFDFF5E3),
      name: 'James C.',
      rating: 5,
      date: 'Jun 7',
      text: 'Great seller! Verified identity gave me peace of mind for our meetup.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Member Reviews',
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ..._reviews.map((r) => _ReviewCard(review: r)),
      ],
    );
  }
}

class _ReviewMock {
  final String emoji;
  final Color bg;
  final String name;
  final int rating;
  final String date;
  final String text;

  const _ReviewMock({
    required this.emoji,
    required this.bg,
    required this.name,
    required this.rating,
    required this.date,
    required this.text,
  });
}

class _ReviewCard extends StatelessWidget {
  final _ReviewMock review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: review.bg, shape: BoxShape.circle),
                child: Center(child: Text(review.emoji, style: const TextStyle(fontSize: 16))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(review.name,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              Text(review.date, style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < review.rating ? Icons.star : Icons.star_border,
                color: AppColors.warning,
                size: 14,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(review.text, style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}
