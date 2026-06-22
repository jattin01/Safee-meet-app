import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/shared/failures/failures.dart';
import '../../domain/entities/verification_entity.dart';
import '../../domain/repositories/verification_repository.dart';
import '../remote_data_sources/verification_remote_data_source.dart';

class VerificationRepositoryImpl implements VerificationRepository {
  final VerificationRemoteDataSource _remote;
  VerificationRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, VerificationStatusEntity>> getVerificationStatus() async {
    try {
      final data = await _remote.getVerificationStatus();
      return Right(_parseStatus(data));
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> uploadIdDocument({
    required File frontImage,
    required File backImage,
  }) async {
    try {
      await _remote.uploadIdDocument(front: frontImage, back: backImage);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> uploadSelfie(File selfie) async {
    try {
      await _remote.uploadSelfie(selfie);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, VerificationEntity>> getVerificationProgress() async {
    try {
      final data = await _remote.getVerificationProgress();
      return Right(_parseProgress(data));
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  VerificationStatusEntity _parseStatus(Map<String, dynamic> d) {
    final reviews = (d['recentReviews'] as List<dynamic>? ?? []).map((r) {
      final m = r as Map<String, dynamic>;
      return ReviewSummaryEntity(
        authorName: m['authorName'] as String,
        rating: (m['rating'] as num).toDouble(),
        text: m['text'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
    }).toList();
    return VerificationStatusEntity(
      trustScore: (d['trustScore'] as num).toInt(),
      verificationLevel: d['verificationLevel'] as String? ?? 'none',
      level1Complete: d['level1Complete'] as bool? ?? false,
      level2Complete: d['level2Complete'] as bool? ?? false,
      professionalComplete: d['professionalComplete'] as bool? ?? false,
      safetyMetricMeetings: (d['safetyMetricMeetings'] as num?)?.toDouble() ?? 0,
      safetyMetricResponsiveness: (d['safetyMetricResponsiveness'] as num?)?.toDouble() ?? 0,
      safetyMetricReviews: (d['safetyMetricReviews'] as num?)?.toDouble() ?? 0,
      recentReviews: reviews,
    );
  }

  VerificationEntity _parseProgress(Map<String, dynamic> d) {
    final stepStr = d['currentStep'] as String? ?? 'uploadId';
    final step = VerificationStep.values.firstWhere(
      (s) => s.name == stepStr,
      orElse: () => VerificationStep.uploadId,
    );
    return VerificationEntity(
      idFrontUrl: d['idFrontUrl'] as String?,
      idBackUrl: d['idBackUrl'] as String?,
      selfieUrl: d['selfieUrl'] as String?,
      currentStep: step,
      status: d['status'] as String? ?? 'pending',
      rejectionReason: d['rejectionReason'] as String?,
    );
  }

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
