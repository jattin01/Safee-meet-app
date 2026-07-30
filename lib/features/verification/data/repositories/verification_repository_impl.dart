import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/shared/failures/failures.dart';
import '../../domain/entities/verification_entity.dart';
import '../../domain/repositories/verification_repository.dart';
import '../remote_data_sources/verification_remote_data_source.dart';

class VerificationRepositoryImpl implements VerificationRepository {
  final VerificationRemoteDataSource _remote;
  final SecureStorageService _storage;
  VerificationRepositoryImpl(this._remote, this._storage);

  VerificationStep _parseStep(String? raw) =>
      VerificationStep.values.firstWhere(
        (s) => s.name == raw,
        orElse: () => VerificationStep.uploadId,
      );

  @override
  Future<Either<Failure, VerificationStatusEntity>>
      getVerificationStatus() async {
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
  Future<Either<Failure, VerificationSubmitResult>> submitVerification({
    required File faceIdImage,
    required File nationalIdFrontImage,
    required File nationalIdBackImage,
    required String nationalIdNumber,
    required String nationalIdCountry,
  }) async {
    try {
      final userId = await _storage.getUserId() ?? '';
      final body = await _remote.submitVerification(
        userId: userId,
        faceIdImage: faceIdImage,
        nationalIdFrontImage: nationalIdFrontImage,
        nationalIdBackImage: nationalIdBackImage,
        nationalIdNumber: nationalIdNumber,
        nationalIdCountry: nationalIdCountry,
      );
      return Right(_parseSubmitResult(body));
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

  // `/v1/auth/me`'s `verificationStatus` reflects the live UserVerification
  // row written by the new /verification/submit flow; the legacy `kycStatus`
  // column on the user is stale and not updated by it, so it's ignored here.
  // Backend returns the literal string 'not_submitted' when no verification
  // row exists yet; normalize that to 'not_started' to match the rest of
  // this entity's status vocabulary (used throughout the status screen).
  VerificationStatusEntity _parseStatus(Map<String, dynamic> d) {
    final raw = d['verificationStatus'] as String? ?? 'not_submitted';
    final workflowStatus = raw == 'not_submitted' ? 'not_started' : raw;
    final level1Complete = workflowStatus == 'approved';
    return VerificationStatusEntity(
      trustScore: (d['trustScore'] as num?)?.toInt() ?? 0,
      verificationLevel: _levelLabel((d['verificationLevel'] as num?)?.toInt()),
      level1Complete: level1Complete,
      level2Complete: false,
      professionalComplete: false,
      kycStatus: workflowStatus,
      currentStep: _stepFromWorkflowStatus(workflowStatus),
      // Not part of the /v1/auth/me contract yet; read opportunistically so
      // the rejection banner picks it up automatically if the backend adds it.
      rejectionReason: d['rejectionReason'] as String?,
      safetyMetricMeetings: level1Complete ? 0.7 : 0.25,
      safetyMetricResponsiveness: level1Complete ? 0.8 : 0.2,
      safetyMetricReviews: level1Complete ? 0.6 : 0.1,
      recentReviews: const [],
    );
  }

  String _levelLabel(int? level) => switch (level) {
        1 => 'level1',
        2 => 'level2',
        3 => 'professional',
        _ => 'none',
      };

  // 'rejected' still had documents + selfie submitted (that's what got
  // reviewed and rejected), so it maps to 'processing' too — otherwise the
  // status screen's checklist would wrongly show those steps as incomplete.
  VerificationStep _stepFromWorkflowStatus(String status) => switch (status) {
        'approved' => VerificationStep.complete,
        'pending' || 'manual_review' || 'rejected' => VerificationStep.processing,
        _ => VerificationStep.uploadId,
      };

  VerificationEntity _parseProgress(Map<String, dynamic> d) {
    return VerificationEntity(
      idFrontUrl: d['idFrontUrl'] as String?,
      idBackUrl: d['idBackUrl'] as String?,
      selfieUrl: d['selfieUrl'] as String?,
      hasIdFront: d['hasIdFront'] as bool? ?? false,
      hasIdBack: d['hasIdBack'] as bool? ?? false,
      hasSelfie: d['hasSelfie'] as bool? ?? false,
      currentStep: _parseStep(d['currentStep'] as String?),
      status: d['status'] as String? ?? 'not_started',
      rejectionReason: d['rejectionReason'] as String?,
    );
  }

  VerificationSubmitResult _parseSubmitResult(Map<String, dynamic> body) {
    final d = body['data'] as Map<String, dynamic>? ?? const {};
    return VerificationSubmitResult(
      message: body['message'] as String? ??
          'Verification documents submitted successfully.',
      data: VerificationSubmitEntity(
        id: (d['id'] as num?)?.toInt() ?? 0,
        userId: d['user_id']?.toString() ?? '',
        faceIdImage: d['face_id_image'] as String? ?? '',
        nationalIdFrontImage: d['national_id_front_image'] as String? ?? '',
        nationalIdBackImage: d['national_id_back_image'] as String? ?? '',
        nationalIdNumber: d['national_id_number'] as String? ?? '',
        nationalIdCountry: d['national_id_country'] as String? ?? '',
        verificationLevel: (d['verification_level'] as num?)?.toInt() ?? 0,
        status: d['status'] as String? ?? 'pending',
      ),
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
