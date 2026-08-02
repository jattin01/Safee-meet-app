import 'package:equatable/equatable.dart';
import 'profile_entity.dart';

/// Full payload of GET /v1/reviews — the aggregate summary block (average,
/// per-star breakdown, punctual/trustworthy/responsive percentages) plus one
/// paginated page of the review list. The summary numbers are computed by
/// the backend over the *unfiltered* set for the reviewee, so they stay the
/// same across star/category filter changes — only [reviews] changes.
class ReviewsSummaryEntity extends Equatable {
  final double averageRating;
  final int totalReviews;

  /// Star (1-5) → count.
  final Map<int, int> breakdown;
  final int punctualPercent;
  final int trustworthyPercent;
  final int responsivePercent;

  final List<ReviewEntity> reviews;
  final int currentPage;
  final int lastPage;
  final String? nextPageUrl;

  const ReviewsSummaryEntity({
    required this.averageRating,
    required this.totalReviews,
    required this.breakdown,
    required this.punctualPercent,
    required this.trustworthyPercent,
    required this.responsivePercent,
    required this.reviews,
    required this.currentPage,
    required this.lastPage,
    this.nextPageUrl,
  });

  bool get hasMore => nextPageUrl != null && currentPage < lastPage;

  int get maxBreakdownCount =>
      breakdown.values.fold(0, (max, v) => v > max ? v : max);

  @override
  List<Object?> get props => [
        averageRating,
        totalReviews,
        breakdown,
        punctualPercent,
        trustworthyPercent,
        responsivePercent,
        reviews,
        currentPage,
        lastPage,
        nextPageUrl,
      ];
}
