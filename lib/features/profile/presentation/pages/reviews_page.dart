import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';

// PROTOTYPE MODE: this page renders mock data only — there is no
// ProfileBloc wiring or backend connectivity. Re-connect it to
// ProfileBloc (ReviewsLoadRequested / ReviewMarkedHelpful) before shipping.
class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewMock {
  final String name;
  final String emoji;
  final Color avatarBg;
  final bool verified;
  final int rating;
  final String date;
  final String tag;
  final Color tagColor;
  final String text;
  final int helpful;

  const _ReviewMock({
    required this.name,
    required this.emoji,
    required this.avatarBg,
    required this.verified,
    required this.rating,
    required this.date,
    required this.tag,
    required this.tagColor,
    required this.text,
    required this.helpful,
  });
}

class _ReviewsPageState extends State<ReviewsPage> {
  String _filter = 'All';

  static const _filters = ['All', '5 ★', '4 ★', 'Marketplace', 'Dating'];

  static const _reviews = [
    _ReviewMock(
      name: 'Sarah Mitchell',
      emoji: '🐱',
      avatarBg: Color(0xFFDCEBFF),
      verified: true,
      rating: 5,
      date: 'Jun 9, 2026',
      tag: 'Marketplace',
      tagColor: AppColors.blue,
      text: 'Alex was incredibly professional and trustworthy. Felt completely '
          'safe during our meeting at the café. The verification system gave '
          'me total confidence. Highly recommended!',
      helpful: 12,
    ),
    _ReviewMock(
      name: 'James Carter',
      emoji: '🦁',
      avatarBg: Color(0xFFDFF5E3),
      verified: true,
      rating: 5,
      date: 'Jun 7, 2026',
      tag: 'Marketplace',
      tagColor: AppColors.blue,
      text: 'Good experience overall. Alex was professional and transparent. '
          'Minor delay but communicated well in advance.',
      helpful: 3,
    ),
    _ReviewMock(
      name: 'Lisa Kim',
      emoji: '👩',
      avatarBg: Color(0xFFFCE4EC),
      verified: false,
      rating: 5,
      date: 'May 21, 2026',
      tag: 'Social',
      tagColor: AppColors.success,
      text: 'Felt completely safe meeting Alex. The SAFEE PIN system and '
          'verification badges made the whole experience stress-free. 10/10 '
          'would recommend to anyone.',
      helpful: 15,
    ),
  ];

  List<_ReviewMock> get _filtered {
    switch (_filter) {
      case '5 ★':
        return _reviews.where((r) => r.rating == 5).toList();
      case '4 ★':
        return _reviews.where((r) => r.rating == 4).toList();
      case 'Marketplace':
        return _reviews.where((r) => r.tag == 'Marketplace').toList();
      case 'Dating':
        return _reviews.where((r) => r.tag == 'Dating').toList();
      default:
        return _reviews;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: Column(
        children: [
          const DarkScreenHeader(
              title: 'Reviews & Ratings', child: _RatingSummary()),
          _FilterChips(
            filters: _filters,
            selected: _filter,
            onSelect: (f) => setState(() => _filter = f),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              itemCount: _filtered.length,
              itemBuilder: (_, i) => _ReviewCard(review: _filtered[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary();

  static const _breakdown = [
    (5, 41),
    (4, 4),
    (3, 2),
    (2, 0),
    (1, 0),
  ];
  static const _maxCount = 41;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBg2,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Text('4.9',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w800)),
                  Row(
                    children: List.generate(
                        5,
                        (i) => const Icon(Icons.star,
                            color: AppColors.warning, size: 14)),
                  ),
                  const SizedBox(height: 2),
                  Text('47 reviews',
                      style: TextStyle(
                          color: AppColors.textTertiary, fontSize: 11)),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: _breakdown
                      .map((b) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Text('${b.$1}',
                                    style: TextStyle(
                                        color: AppColors.textTertiary,
                                        fontSize: 11)),
                                const SizedBox(width: 3),
                                const Icon(Icons.star,
                                    color: AppColors.warning, size: 10),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: b.$2 / _maxCount,
                                      minHeight: 5,
                                      backgroundColor:
                                          Colors.white.withOpacity(0.08),
                                      valueColor: const AlwaysStoppedAnimation(
                                          AppColors.warning),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 18,
                                  child: Text('${b.$2}',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          color: AppColors.textTertiary,
                                          fontSize: 11)),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: _StatPill(value: '98%', label: 'Punctual')),
              SizedBox(width: 10),
              Expanded(child: _StatPill(value: '100%', label: 'Trustworthy')),
              SizedBox(width: 10),
              Expanded(child: _StatPill(value: '95%', label: 'Responsive')),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  const _StatPill({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelect;

  const _FilterChips(
      {required this.filters, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: filters.map((f) {
          final active = selected == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(f),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: active ? AppColors.primary : AppColors.border),
                ),
                child: Text(
                  f,
                  style: GoogleFonts.inter(
                    color: active ? Colors.white : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReviewCard extends StatefulWidget {
  final _ReviewMock review;
  const _ReviewCard({required this.review});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  late int _helpful;

  @override
  void initState() {
    super.initState();
    _helpful = widget.review.helpful;
  }

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: review.avatarBg, shape: BoxShape.circle),
                child: Center(
                    child: Text(review.emoji,
                        style: const TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(review.name,
                            style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(width: 5),
                        Icon(
                          review.verified
                              ? Icons.verified
                              : Icons.shield_outlined,
                          color: review.verified
                              ? AppColors.blue
                              : AppColors.textTertiary,
                          size: 14,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        ...List.generate(
                            5,
                            (i) => Icon(
                                  i < review.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: AppColors.warning,
                                  size: 13,
                                )),
                        const SizedBox(width: 6),
                        Text('· ${review.date}',
                            style: TextStyle(
                                color: AppColors.textTertiary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: review.tagColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  review.tag,
                  style: GoogleFonts.inter(
                      color: review.tagColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(review.text,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _helpful++),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.thumb_up_outlined,
                          color: AppColors.textSecondary, size: 13),
                      const SizedBox(width: 6),
                      Text('Helpful ($_helpful)',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.check_circle, color: AppColors.success, size: 14),
              const SizedBox(width: 4),
              Text(
                'Verified Meeting',
                style: GoogleFonts.inter(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
