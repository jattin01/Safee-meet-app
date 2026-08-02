import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/shared/failures/dio_failure_mapper.dart';
import '../../../../core/shared/failures/failures.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/reviews_summary_entity.dart';
import '../../domain/entities/submitted_review_entity.dart';

abstract class ProfileRepository {
  Future<Either<Failure, ProfileEntity>> getProfile();
  Future<Either<Failure, List<ReviewEntity>>> getReviews({
    String? filter,
    int page = 1,
  });
  Future<Either<Failure, void>> markReviewHelpful(String reviewId);

  /// GET /v1/reviews — the signed-in user's own received reviews (summary +
  /// one paginated page of the list). [stars]/[category] map to the
  /// backend's `?stars=`/`?category=` filters; both are applied server-side
  /// to the *list*, never to the summary numbers (the backend computes those
  /// over the reviewee's unfiltered set).
  Future<Either<Failure, ReviewsSummaryEntity>> getReviewsList({
    int? stars,
    String? category,
    required int page,
  });

  /// POST /v1/meetings/{meeting}/review. [userId] is the reviewer's own id
  /// (the currently signed-in user) — the backend derives who is being
  /// reviewed from the meeting's host/guest pair, it is not passed
  /// explicitly.
  Future<Either<Failure, SubmittedReviewEntity>> submitReview({
    required String meetingId,
    required int userId,
    required int rating,
    String? comment,
    required bool punctual,
    required bool trustworthy,
    required bool responsive,
  });
}

class ProfileRepositoryImpl implements ProfileRepository {
  final ApiClient _api;
  final SecureStorageService _storage;

  ProfileRepositoryImpl(this._api, this._storage);

  @override
  Future<Either<Failure, ProfileEntity>> getProfile() async {
    try {
      final res = await _api.dio.get('/v1/auth/me');
      final body = res.data as Map<String, dynamic>;
      final user = (body['data']?['user'] ?? body['data'] ?? body)
          as Map<String, dynamic>;
      final phone = await _storage.getUserPhone();
      return Right(_parseProfile(user, phone: phone));
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, List<ReviewEntity>>> getReviews({
    String? filter,
    int page = 1,
  }) async {
    try {
      final res = await _api.dio.get('/v1/profile/reviews', queryParameters: {
        if (filter != null) 'filter': filter,
        'page': page,
      });
      final list = (res.data as List<dynamic>)
          .map((r) => _parseReview(r as Map<String, dynamic>))
          .toList();
      return Right(list);
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, ReviewsSummaryEntity>> getReviewsList({
    int? stars,
    String? category,
    required int page,
  }) async {
    try {
      final res = await _api.dio.get('/v1/reviews', queryParameters: {
        if (stars != null) 'stars': stars,
        if (category != null) 'category': category,
        'page': page,
      });
      final body = res.data as Map<String, dynamic>;
      return Right(_parseReviewsSummary(body));
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> markReviewHelpful(String reviewId) async {
    try {
      await _api.dio.post('/v1/reviews/$reviewId/helpful');
      return const Right(null);
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, SubmittedReviewEntity>> submitReview({
    required String meetingId,
    required int userId,
    required int rating,
    String? comment,
    required bool punctual,
    required bool trustworthy,
    required bool responsive,
  }) async {
    try {
      final res = await _api.dio.post('/v1/meetings/$meetingId/review', data: {
        'user_id': userId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        'punctual': punctual,
        'trustworthy': trustworthy,
        'responsive': responsive,
      });
      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      return Right(_parseSubmittedReview(data, meetingId));
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  ProfileEntity _parseProfile(Map<String, dynamic> d, {String? phone}) =>
      ProfileEntity(
        id: d['id'] as String? ?? '',
        name: d['displayName'] as String? ?? 'SAFEE User',
        safeePIN: d['safeeId'] as String? ?? '',
        avatarUrl: d['avatarUrl'] as String?,
        phone: d['phone'] as String? ?? phone,
        email: d['email'] as String?,
        trustScore: (d['trustScore'] as num?)?.toInt() ?? 0,
        verificationLevel: _resolveVerificationLevel(d),
        pinSearchCount: (d['pinSearchCount'] as num?)?.toInt() ?? 0,
        subscriptionPlan: 'free',
        // Same plain `rating` key member-search's parser already reads
        // successfully off a user object — this was previously hardcoded to
        // 0, which is why the Home dashboard's rating stat never moved.
        rating: (d['rating'] as num?)?.toDouble() ?? 0,
        totalMeetings: (d['meetingCount'] as num?)?.toInt() ?? 0,
        totalReviews: 0,
        badges: [],
        status: d['status'] as String?,
        createdAt: d['createdAt'] != null
            ? DateTime.tryParse(d['createdAt'] as String)
            : null,
      );

  // `trustTier` is derived server-side from the legacy kyc_status/trust_tier
  // columns, which the new /verification/submit flow never updates — so it
  // stays stuck on 'none' even after approval. `verificationStatus` +
  // `verificationLevel` reflect the live UserVerification row instead.
  String _resolveVerificationLevel(Map<String, dynamic> d) {
    if (d['verificationStatus'] != 'approved') return 'none';
    return switch ((d['verificationLevel'] as num?)?.toInt()) {
      1 => 'low',
      2 => 'medium',
      3 => 'high',
      _ => 'none',
    };
  }

  ReviewEntity _parseReview(Map<String, dynamic> d) => ReviewEntity(
        id: d['id'] as String,
        authorId: d['authorId'] as String,
        authorName: d['authorName'] as String,
        authorAvatarUrl: d['authorAvatarUrl'] as String?,
        rating: (d['rating'] as num).toDouble(),
        text: d['text'] as String,
        verifiedMeeting: d['verifiedMeeting'] as bool? ?? false,
        createdAt: DateTime.parse(d['createdAt'] as String),
        helpfulCount: (d['helpfulCount'] as num?)?.toInt() ?? 0,
      );

  ReviewsSummaryEntity _parseReviewsSummary(Map<String, dynamic> body) {
    final breakdownJson = body['breakdown'] as Map<String, dynamic>? ?? const {};
    final breakdown = <int, int>{
      for (final entry in breakdownJson.entries)
        int.parse(entry.key): (entry.value as num).toInt(),
    };

    final paginator = body['reviews'] as Map<String, dynamic>? ?? const {};
    final items = (paginator['data'] as List<dynamic>? ?? const [])
        .map((r) => _parseReviewListItem(r as Map<String, dynamic>))
        .toList();

    // The count across *all* pages lives on the paginator itself (Laravel's
    // standard `total` field — the same object `current_page`/`last_page`
    // already come from) — not a top-level `total_reviews` key, which the
    // backend doesn't actually send. Reading the wrong key silently defaulted
    // to 0 while `items` (parsed from `reviews.data`) was populated fine,
    // producing the "0 Reviews" label next to real review cards.
    final totalReviews = (body['total_reviews'] as num?)?.toInt() ??
        (paginator['total'] as num?)?.toInt() ??
        items.length;

    return ReviewsSummaryEntity(
      averageRating: (body['average_rating'] as num?)?.toDouble() ?? 0,
      totalReviews: totalReviews,
      breakdown: breakdown,
      punctualPercent: (body['punctual_percent'] as num?)?.toInt() ?? 0,
      trustworthyPercent: (body['trustworthy_percent'] as num?)?.toInt() ?? 0,
      responsivePercent: (body['responsive_percent'] as num?)?.toInt() ?? 0,
      reviews: items,
      currentPage: (paginator['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (paginator['last_page'] as num?)?.toInt() ?? 1,
      nextPageUrl: paginator['next_page_url'] as String?,
    );
  }

  ReviewEntity _parseReviewListItem(Map<String, dynamic> d) {
    final reviewer = d['reviewer'] as Map<String, dynamic>? ?? const {};
    final meeting = d['meeting'] as Map<String, dynamic>? ?? const {};
    return ReviewEntity(
      id: d['id'].toString(),
      authorId: reviewer['id']?.toString() ?? '',
      authorName: reviewer['name'] as String? ?? 'SAFEE User',
      // GET /v1/reviews doesn't return a reviewer avatar — the UI falls
      // back to initials, same as everywhere else in the app.
      authorAvatarUrl: null,
      authorVerificationLevel: reviewer['verification_level'] as String? ?? 'none',
      rating: (d['rating'] as num?)?.toDouble() ?? 0,
      text: d['comment'] as String? ?? '',
      // Reviews only ever exist for completed meetings (the backend
      // rejects POST /meetings/{id}/review otherwise), so every row this
      // endpoint returns is inherently meeting-verified.
      verifiedMeeting: true,
      meetingType: meeting['type'] as String?,
      punctual: d['punctual'] as bool? ?? false,
      trustworthy: d['trustworthy'] as bool? ?? false,
      responsive: d['responsive'] as bool? ?? false,
      createdAt: DateTime.tryParse(d['created_at'] as String? ?? '') ?? DateTime.now(),
      helpfulCount: (d['helpful_count'] as num?)?.toInt() ?? 0,
    );
  }

  SubmittedReviewEntity _parseSubmittedReview(
    Map<String, dynamic> d,
    String meetingId,
  ) =>
      SubmittedReviewEntity(
        id: (d['id'] as num).toInt(),
        meetingId: d['meeting_id']?.toString() ?? meetingId,
        reviewerId: int.tryParse(d['reviewer_id']?.toString() ?? '') ?? 0,
        revieweeId: int.tryParse(d['reviewee_id']?.toString() ?? '') ?? 0,
        rating: (d['rating'] as num?)?.toInt() ?? 0,
        comment: d['comment'] as String?,
        punctual: d['punctual'] as bool? ?? false,
        trustworthy: d['trustworthy'] as bool? ?? false,
        responsive: d['responsive'] as bool? ?? false,
        helpfulCount: (d['helpful_count'] as num?)?.toInt() ?? 0,
        createdAt: d['created_at'] != null
            ? DateTime.tryParse(d['created_at'] as String)
            : null,
      );

  Failure _map(DioException e) => mapDioException(e);
}
