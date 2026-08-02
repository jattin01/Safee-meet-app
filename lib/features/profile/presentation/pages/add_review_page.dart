import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/shared/utils/safe_bottom_padding.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';
import '../../../../core/shared/widgets/primary_button.dart';
import '../cubit/submit_review_cubit.dart';

/// Everything the Add Review screen needs to know about who it's rating —
/// passed via `extra` when navigating here (see live_location_page.dart's
/// end-meeting flow), since none of it is derivable from a URL path.
class AddReviewArgs {
  final String meetingId;
  final int revieweeId;
  final String revieweeName;
  final String? revieweeAvatarUrl;

  const AddReviewArgs({
    required this.meetingId,
    required this.revieweeId,
    required this.revieweeName,
    this.revieweeAvatarUrl,
  });
}

class AddReviewPage extends StatefulWidget {
  final AddReviewArgs args;
  const AddReviewPage({super.key, required this.args});

  @override
  State<AddReviewPage> createState() => _AddReviewPageState();
}

class _AddReviewPageState extends State<AddReviewPage> {
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _punctual = false;
  bool _trustworthy = false;
  bool _responsive = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _leaveFlow() => context.go('${AppRoutes.meetings}?tab=past');

  void _submit() {
    if (_rating == 0) return;
    context.read<SubmitReviewCubit>().submit(
          meetingId: widget.args.meetingId,
          userId: widget.args.revieweeId,
          rating: _rating,
          comment: _commentController.text.trim(),
          punctual: _punctual,
          trustworthy: _trustworthy,
          responsive: _responsive,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: BlocConsumer<SubmitReviewCubit, SubmitReviewState>(
        listener: (context, state) {
          if (state.status == SubmitReviewStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Review submitted successfully.')),
            );
            _leaveFlow();
          } else if (state.status == SubmitReviewStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Unable to submit review.'),
                action: SnackBarAction(label: 'Retry', onPressed: _submit),
              ),
            );
          }
        },
        builder: (context, state) {
          final isSubmitting = state.status == SubmitReviewStatus.submitting;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DarkScreenHeader(
                  title: 'Rate Your Meeting',
                  titleFontSize: 18,
                  trailing: TextButton(
                    onPressed: isSubmitting ? null : _leaveFlow,
                    child: Text(
                      'Skip',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      20, 28, 20, context.bottomSafePadding(32)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _RevieweeHeader(
                        name: widget.args.revieweeName,
                        avatarUrl: widget.args.revieweeAvatarUrl,
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: _StarSelector(
                          rating: _rating,
                          onChanged: isSubmitting
                              ? (_) {}
                              : (v) => setState(() => _rating = v),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _ratingLabel(_rating),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'ADD A COMMENT (OPTIONAL)',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _commentController,
                        enabled: !isSubmitting,
                        maxLines: 4,
                        maxLength: 2000,
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Share your experience meeting them…',
                          hintStyle: TextStyle(color: AppColors.textTertiary),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'WOULD YOU RECOMMEND THEM?',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _RecommendationChip(
                            label: 'Punctual',
                            icon: Icons.schedule,
                            selected: _punctual,
                            onTap: isSubmitting
                                ? null
                                : () => setState(() => _punctual = !_punctual),
                          ),
                          _RecommendationChip(
                            label: 'Trustworthy',
                            icon: Icons.verified_user_outlined,
                            selected: _trustworthy,
                            onTap: isSubmitting
                                ? null
                                : () => setState(() => _trustworthy = !_trustworthy),
                          ),
                          _RecommendationChip(
                            label: 'Responsive',
                            icon: Icons.chat_bubble_outline,
                            selected: _responsive,
                            onTap: isSubmitting
                                ? null
                                : () => setState(() => _responsive = !_responsive),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      PrimaryButton(
                        label: 'Submit Review',
                        isLoading: isSubmitting,
                        onPressed: _rating == 0 ? null : _submit,
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: TextButton(
                          onPressed: isSubmitting ? null : _leaveFlow,
                          child: Text(
                            'Skip for now',
                            style: GoogleFonts.inter(
                              color: AppColors.textTertiary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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
        },
      ),
    );
  }
}

String _ratingLabel(int rating) => switch (rating) {
      0 => 'Tap a star to rate',
      1 => 'Poor',
      2 => 'Fair',
      3 => 'Good',
      4 => 'Very Good',
      _ => 'Excellent',
    };

class _RevieweeHeader extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  const _RevieweeHeader({required this.name, this.avatarUrl});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
          child: avatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _InitialsText(_initials),
                  ),
                )
              : _InitialsText(_initials),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'How was your meeting?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _InitialsText extends StatelessWidget {
  final String initials;
  const _InitialsText(this.initials);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StarSelector extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;
  const _StarSelector({required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starValue = i + 1;
        return GestureDetector(
          onTap: () => onChanged(starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              starValue <= rating ? Icons.star : Icons.star_border,
              color: AppColors.warning,
              size: 42,
            ),
          ),
        );
      }),
    );
  }
}

class _RecommendationChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _RecommendationChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.success.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.success : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle : icon,
              color: selected ? AppColors.success : AppColors.textSecondary,
              size: 17,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: selected ? AppColors.success : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
