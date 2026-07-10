import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/secure_storage_service.dart';
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

  ProfileEntity _parseProfile(Map<String, dynamic> d, {String? phone}) =>
      ProfileEntity(
        id: d['id'] as String? ?? '',
        name: d['displayName'] as String? ?? 'SAFEE User',
        safeePIN: d['safeeId'] as String? ?? '',
        avatarUrl: d['avatarUrl'] as String?,
        phone: d['phone'] as String? ?? phone,
        email: d['email'] as String?,
        trustScore: (d['trustScore'] as num?)?.toInt() ?? 0,
        verificationLevel: d['trustTier'] as String? ?? 'none',
        pinSearchCount: (d['pinSearchCount'] as num?)?.toInt() ?? 0,
        subscriptionPlan: 'free',
        rating: 0,
        totalMeetings: (d['meetingCount'] as num?)?.toInt() ?? 0,
        totalReviews: 0,
        badges: [],
        status: d['status'] as String?,
        createdAt: d['createdAt'] != null
            ? DateTime.tryParse(d['createdAt'] as String)
            : null,
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
