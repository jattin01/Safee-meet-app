import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/dependency_injection/injection_container.dart';
import '../../../../core/shared/widgets/dark_screen_header.dart';
import '../../../../core/shared/utils/safe_bottom_padding.dart';
import '../../../../core/shared/widgets/no_internet_view.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/reviews_summary_entity.dart';
import '../cubit/reviews_cubit.dart';

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      // ReviewsCubit is an app-lifetime DI singleton (see
      // injection_container.dart) that ProfilePage's review-preview card
      // also primes via a plain `..load()`. That call is a no-op once the
      // cubit is already `loaded` (see ReviewsCubit.load's guard), so
      // without forceRefresh here, navigating into this dedicated Reviews
      // page would just keep showing whatever the cubit last had —
      // possibly stale — until the user manually pulled to refresh.
      // Force a refetch every time this page is (re)pushed instead.
      value: sl<ReviewsCubit>()..load(forceRefresh: true),
      child: const _ReviewsView(),
    );
  }
}

// Chip label -> the ReviewsFilter it triggers. The Marketplace/Dating
// category chips were removed — that filtering is no longer offered on
// this screen — leaving just the star-rating filters.
const Map<String, ReviewsFilter> _kFilterOptions = {
  'All': ReviewsFilter.all,
  '5 ★': ReviewsFilter(stars: 5),
  '4 ★': ReviewsFilter(stars: 4),
};

class _ReviewsView extends StatefulWidget {
  const _ReviewsView();

  @override
  State<_ReviewsView> createState() => _ReviewsViewState();
}

class _ReviewsViewState extends State<_ReviewsView> {
  final ScrollController _scrollController = ScrollController();
  String _selectedFilterLabel = 'All';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      context.read<ReviewsCubit>().loadMore();
    }
  }

  void _onSelectFilter(String label) {
    setState(() => _selectedFilterLabel = label);
    context.read<ReviewsCubit>().load(filter: _kFilterOptions[label]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: BlocBuilder<ReviewsCubit, ReviewsState>(
        builder: (context, state) {
          return Column(
            children: [
              DarkScreenHeader(
                title: 'Reviews & Ratings',
                child: state.summary != null
                    ? _RatingSummary(summary: state.summary!)
                    : const _RatingSummarySkeleton(),
              ),
              _FilterChips(
                filters: _kFilterOptions.keys.toList(),
                selected: _selectedFilterLabel,
                onSelect: _onSelectFilter,
              ),
              Expanded(child: _buildBody(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ReviewsState state) {
    if ((state.status == ReviewsStatus.initial ||
            state.status == ReviewsStatus.loading) &&
        state.reviews.isEmpty) {
      return const _ReviewsListSkeleton();
    }

    if (state.status == ReviewsStatus.error && state.reviews.isEmpty) {
      void retry() => context.read<ReviewsCubit>().load(forceRefresh: true);
      if (state.isNetworkError) {
        return NoInternetView(onRetry: retry);
      }
      return _ErrorState(
        message: state.errorMessage ?? 'Something went wrong.',
        onRetry: retry,
      );
    }

    if (state.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<ReviewsCubit>().load(forceRefresh: true),
        child: const _EmptyState(),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<ReviewsCubit>().load(forceRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, 4, 20, context.bottomSafePadding(24)),
        itemCount: state.reviews.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.reviews.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final review = state.reviews[index];
          return _ReviewCard(
            review: review,
            onHelpful: () =>
                context.read<ReviewsCubit>().markHelpful(review.id),
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: AppColors.textTertiary, size: 44),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.12),
                          AppColors.primaryLight.withOpacity(0.06),
                        ],
                      ),
                    ),
                    child: const Icon(Icons.star_border,
                        color: AppColors.primary, size: 38),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No Reviews Found',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You don't have any reviews matching this filter yet.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final ReviewsSummaryEntity summary;
  const _RatingSummary({required this.summary});

  @override
  Widget build(BuildContext context) {
    final maxCount = summary.maxBreakdownCount == 0 ? 1 : summary.maxBreakdownCount;
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
                  Text(summary.averageRating.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1)),
                  Row(
                    children: List.generate(
                        5,
                        (i) => const Icon(Icons.star_rounded,
                            color: AppColors.warning, size: 16)),
                  ),
                  const SizedBox(height: 4),
                  Text('${summary.totalReviews} reviews',
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 11)),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    for (var star = 5; star >= 1; star--)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Text('$star',
                                style: const TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 11)),
                            const SizedBox(width: 3),
                            const Icon(Icons.star_rounded,
                                color: AppColors.warning, size: 12),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: (summary.breakdown[star] ?? 0) / maxCount,
                                  minHeight: 6,
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
                              child: Text('${summary.breakdown[star] ?? 0}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _StatPill(
                      value: '${summary.punctualPercent}%',
                      label: 'Punctual')),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatPill(
                      value: '${summary.trustworthyPercent}%',
                      label: 'Trustworthy')),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatPill(
                      value: '${summary.responsivePercent}%',
                      label: 'Responsive')),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatingSummarySkeleton extends StatelessWidget {
  const _RatingSummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 172,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBg2,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const _ShimmerBox(width: double.infinity, height: double.infinity),
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
      height: 64, // Slightly taller to accommodate shadow
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: filters.map((f) {
          final active = selected == f;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onSelect(f),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                        color: active ? AppColors.primary : AppColors.border),
                    boxShadow: [
                      if (!active)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      if (active)
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Text(
                    f,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: GoogleFonts.inter(
                      color: active ? Colors.white : AppColors.textSecondary,
                      fontSize: 13.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      height: 1.2,
                    ),
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

// A small fixed palette to give avatars some visual variety, picked
// deterministically from the reviewer's id — not a per-review hardcoded
// value, just a stable cosmetic choice.
const List<Color> _kAvatarPalette = [
  Color(0xFFDCEBFF),
  Color(0xFFDFF5E3),
  Color(0xFFFCE4EC),
  Color(0xFFFFF3CD),
  Color(0xFFE6E0FF),
];

Color _avatarColorFor(String seed) =>
    _kAvatarPalette[seed.hashCode.abs() % _kAvatarPalette.length];



class _ReviewCard extends StatelessWidget {
  final ReviewEntity review;
  final VoidCallback onHelpful;
  const _ReviewCard({required this.review, required this.onHelpful});

  @override
  Widget build(BuildContext context) {
    final tag = review.meetingType;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                    color: _avatarColorFor(review.authorId),
                    shape: BoxShape.circle),
                child: Center(
                    child: Text(review.authorInitials,
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(review.authorName,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          review.rating.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        ...List.generate(
                            5,
                            (i) => Icon(
                                  i < review.rating.round()
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: AppColors.warning,
                                  size: 14,
                                )),
                        const SizedBox(width: 6),
                        Text('· ${DateFormat('MMM d, yyyy').format(review.createdAt)}',
                            style: TextStyle(
                                color: AppColors.textTertiary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              if (tag != null && tag.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag[0].toUpperCase() + tag.substring(1),
                    style: GoogleFonts.inter(
                        color: AppColors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          if (review.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(review.text,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
          ],
          if (review.punctual || review.trustworthy || review.responsive) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (review.punctual) const _RecommendationBadge(label: 'Punctual'),
                if (review.trustworthy)
                  const _RecommendationBadge(label: 'Trustworthy'),
                if (review.responsive)
                  const _RecommendationBadge(label: 'Responsive'),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: onHelpful,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.thumb_up_outlined,
                          color: AppColors.textSecondary, size: 14),
                      const SizedBox(width: 6),
                      Text('Helpful (${review.helpfulCount})',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              if (review.verifiedMeeting) ...[
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Verified Meeting',
                  style: GoogleFonts.inter(
                      color: AppColors.success,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RecommendationBadge extends StatelessWidget {
  final String label;
  const _RecommendationBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
                color: AppColors.success, fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer loading (no external shimmer package in this project) ─────────

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  const _ShimmerBox({required this.width, required this.height, this.borderRadius});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 3, 0),
              end: Alignment(0 + t * 3, 0),
              colors: const [
                AppColors.cardBg,
                AppColors.border,
                AppColors.cardBg,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReviewCardSkeleton extends StatelessWidget {
  const _ReviewCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ShimmerBox(width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(20))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _ShimmerBox(width: 120, height: 13),
                SizedBox(height: 8),
                _ShimmerBox(width: 80, height: 11),
                SizedBox(height: 12),
                _ShimmerBox(width: double.infinity, height: 12),
                SizedBox(height: 6),
                _ShimmerBox(width: double.infinity, height: 12),
                SizedBox(height: 6),
                _ShimmerBox(width: 160, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsListSkeleton extends StatelessWidget {
  const _ReviewsListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20, 4, 20, context.bottomSafePadding(24)),
      itemCount: 4,
      itemBuilder: (_, __) => const _ReviewCardSkeleton(),
    );
  }
}
