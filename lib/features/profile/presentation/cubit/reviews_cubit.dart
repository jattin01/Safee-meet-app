import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/shared/failures/failures.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/reviews_summary_entity.dart';
import '../../domain/use_cases/get_reviews_list_use_case.dart';

class ReviewsFilter extends Equatable {
  final int? stars;
  final String? category;
  const ReviewsFilter({this.stars, this.category});

  static const all = ReviewsFilter();

  @override
  List<Object?> get props => [stars, category];
}

enum ReviewsStatus {
  initial,
  loading,
  refreshing,
  loadingMore,
  loaded,
  error,
}

class ReviewsState extends Equatable {
  final ReviewsStatus status;
  final ReviewsSummaryEntity? summary;
  final List<ReviewEntity> reviews;
  final int currentPage;
  final bool hasMore;
  final ReviewsFilter filter;
  final String? errorMessage;
  final bool isNetworkError;

  const ReviewsState({
    this.status = ReviewsStatus.initial,
    this.summary,
    this.reviews = const [],
    this.currentPage = 0,
    this.hasMore = true,
    this.filter = ReviewsFilter.all,
    this.errorMessage,
    this.isNetworkError = false,
  });

  bool get isEmpty => status == ReviewsStatus.loaded && reviews.isEmpty;

  ReviewsState copyWith({
    ReviewsStatus? status,
    ReviewsSummaryEntity? summary,
    List<ReviewEntity>? reviews,
    int? currentPage,
    bool? hasMore,
    ReviewsFilter? filter,
    String? errorMessage,
    bool isNetworkError = false,
    bool clearError = false,
  }) {
    return ReviewsState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      reviews: reviews ?? this.reviews,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      filter: filter ?? this.filter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isNetworkError: clearError ? false : isNetworkError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        summary,
        reviews,
        currentPage,
        hasMore,
        filter,
        errorMessage,
        isNetworkError,
      ];
}

/// Backs the "Reviews & Ratings" screen (GET /v1/reviews — the signed-in
/// user's own received reviews).
class ReviewsCubit extends Cubit<ReviewsState> {
  final GetReviewsListUseCase _getReviews;
  final ProfileRepository _repository;
  final ConnectivityService _connectivity;

  ReviewsCubit(this._getReviews, this._repository, this._connectivity)
      : super(const ReviewsState());

  /// Loads page 1 for [filter] (defaults to the current filter). A no-op if
  /// a fetch is already in flight, or — unless [forceRefresh] or the filter
  /// is actually changing — if page 1 has already loaded, so switching back
  /// to a screen already showing reviews doesn't refire the request.
  Future<void> load({ReviewsFilter? filter, bool forceRefresh = false}) async {
    final busy = state.status == ReviewsStatus.loading ||
        state.status == ReviewsStatus.refreshing ||
        state.status == ReviewsStatus.loadingMore;
    if (busy) return;

    final targetFilter = filter ?? state.filter;
    final isFilterChange = targetFilter != state.filter;
    if (!forceRefresh &&
        !isFilterChange &&
        state.status == ReviewsStatus.loaded) {
      return;
    }

    emit(state.copyWith(
      status: state.reviews.isEmpty || isFilterChange
          ? ReviewsStatus.loading
          : ReviewsStatus.refreshing,
      filter: targetFilter,
      clearError: true,
    ));

    // Check connectivity up front instead of firing the request and waiting
    // on a Dio timeout — shows the No Internet state immediately.
    if (!await _connectivity.isConnected) {
      emit(state.copyWith(
        status: ReviewsStatus.error,
        errorMessage: const NetworkFailure().message,
        isNetworkError: true,
      ));
      return;
    }

    final result = await _getReviews(
      stars: targetFilter.stars,
      category: targetFilter.category,
      page: 1,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        status: ReviewsStatus.error,
        errorMessage: failure.message,
        isNetworkError: failure is NetworkFailure,
      )),
      (summary) => emit(ReviewsState(
        status: ReviewsStatus.loaded,
        summary: summary,
        reviews: summary.reviews,
        currentPage: summary.currentPage,
        hasMore: summary.hasMore,
        filter: targetFilter,
      )),
    );
  }

  /// Fetches the next page (same filter) and appends it. No-op if there's
  /// nothing more, or a fetch is already running — guards against duplicate
  /// calls from fast/repeated scroll events.
  Future<void> loadMore() async {
    if (state.status != ReviewsStatus.loaded || !state.hasMore) return;

    emit(state.copyWith(status: ReviewsStatus.loadingMore));

    final result = await _getReviews(
      stars: state.filter.stars,
      category: state.filter.category,
      page: state.currentPage + 1,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        status: ReviewsStatus.loaded,
        errorMessage: failure.message,
        isNetworkError: failure is NetworkFailure,
      )),
      (summary) => emit(state.copyWith(
        status: ReviewsStatus.loaded,
        reviews: [...state.reviews, ...summary.reviews],
        currentPage: summary.currentPage,
        hasMore: summary.hasMore,
        clearError: true,
      )),
    );
  }

  /// Optimistically bumps the helpful count locally, then fires
  /// POST /v1/reviews/{review}/helpful in the background.
  Future<void> markHelpful(String reviewId) async {
    final index = state.reviews.indexWhere((r) => r.id == reviewId);
    if (index == -1) return;

    final updated = [...state.reviews];
    final current = updated[index];
    updated[index] = current.copyWith(helpfulCount: current.helpfulCount + 1);
    emit(state.copyWith(reviews: updated));

    final result = await _repository.markReviewHelpful(reviewId);
    result.fold(
      (failure) => debugPrint(
          '[Reviews] markHelpful($reviewId) failed: ${failure.message}'),
      (_) {},
    );
  }
}
