import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/shared/failures/failures.dart';
import '../../domain/entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<Either<Failure, ProfileEntity>> getProfile();
  Future<Either<Failure, List<ReviewEntity>>> getReviews({
    String? filter,
    int page = 1,
  });
  Future<Either<Failure, void>> markReviewHelpful(String reviewId);
}

class ProfileRepositoryImpl implements ProfileRepository {
  final ApiClient _api;
  ProfileRepositoryImpl(this._api);

  @override
  Future<Either<Failure, ProfileEntity>> getProfile() async {
    try {
      final res = await _api.dio.get('/profile');
      return Right(_parseProfile(res.data as Map<String, dynamic>));
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
      final res = await _api.dio.get('/profile/reviews', queryParameters: {
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
  Future<Either<Failure, void>> markReviewHelpful(String reviewId) async {
    try {
      await _api.dio.post('/reviews/$reviewId/helpful');
      return const Right(null);
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  ProfileEntity _parseProfile(Map<String, dynamic> d) => ProfileEntity(
        id: d['id'] as String,
        name: d['name'] as String,
        safeePIN: d['safeePIN'] as String,
        avatarUrl: d['avatarUrl'] as String?,
        coverUrl: d['coverUrl'] as String?,
        trustScore: (d['trustScore'] as num).toInt(),
        verificationLevel: d['verificationLevel'] as String? ?? 'none',
        subscriptionPlan: d['subscriptionPlan'] as String? ?? 'free',
        rating: (d['rating'] as num?)?.toDouble() ?? 0,
        totalMeetings: (d['totalMeetings'] as num?)?.toInt() ?? 0,
        totalReviews: (d['totalReviews'] as num?)?.toInt() ?? 0,
        badges: List<String>.from(d['badges'] as List? ?? []),
        bio: d['bio'] as String?,
        city: d['city'] as String?,
      );

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

  Failure _map(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.unknown) {
      return const NetworkFailure();
    }
    return ServerFailure(
      e.response?.data?['message'] as String? ?? 'Server error',
      statusCode: e.response?.statusCode,
    );
  }
}
