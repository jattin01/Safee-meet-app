import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/shared/failures/dio_failure_mapper.dart';
import '../../../../core/shared/failures/failures.dart';
import '../../domain/entities/verification_entity.dart';
import '../../domain/repositories/verification_repository.dart';
import '../remote_data_sources/verification_remote_data_source.dart';

class VerificationRepositoryImpl implements VerificationRepository {
  final VerificationRemoteDataSource _remote;
  final SecureStorageService _storage;
  VerificationRepositoryImpl(this._remote, this._storage);

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
  Future<Either<Failure, DiditSessionEntity>> createDiditSession() async {
    try {
      final data = await _remote.createDiditSession();
      return Right(_parseDiditSession(data));
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, BackgroundConsentEntity>>
      submitBackgroundConsent() async {
    try {
      final data = await _remote.submitBackgroundConsent();
      final success = data['success'] == true;
      final accepted =
          (data['data'] as Map<String, dynamic>?)?['accepted'] == true;
      if (!success || !accepted) {
        return const Left(
            ServerFailure('Consent was not accepted by the server.'));
      }
      // Persist locally so the popup is skipped on future taps.
      await _storage.saveBgConsentAccepted();
      return Right(_parseConsent(data['data'] as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(_map(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<bool> hasBackgroundConsent() => _storage.getBgConsentAccepted();

  // ── Parsers ────────────────────────────────────────────────────────────────

  // `/v1/auth/me`'s `verificationStatus` reflects the live UserVerification
  // row written by the Didit-driven flow; the legacy `kycStatus` column on
  // the user is stale and not updated by it, so it's ignored here.
  // Backend returns the literal string 'not_submitted' when no verification
  // row exists yet; normalize that to 'not_started' to match the rest of
  // this entity's status vocabulary (used throughout the status screen).
  VerificationStatusEntity _parseStatus(Map<String, dynamic> d) {
    final raw = d['verificationStatus'] as String? ?? 'not_submitted';
    final workflowStatus = raw == 'not_submitted' ? 'not_started' : raw;
    final level1Complete = workflowStatus == 'approved';
    final safetyScore = (d['safetyScore'] as num?)?.toInt() ?? 0;
    final parsedLevel = _levelLabel(_parseLevelId(d));
    return VerificationStatusEntity(
      trustScore: (d['trustScore'] as num?)?.toInt() ?? 0,
      safetyScore: safetyScore,
      verificationLevel: parsedLevel,
      level1Complete: level1Complete,
      level2Complete: parsedLevel == 'level2' || parsedLevel == 'level3',
      professionalComplete: parsedLevel == 'level3',
      kycStatus: workflowStatus,
      currentStep: _stepFromWorkflowStatus(workflowStatus),
      // Not part of the /v1/auth/me contract yet; read opportunistically so
      // the rejection banner picks it up automatically if the backend adds it.
      rejectionReason: d['rejectionReason'] as String?,
      safetyMetricMeetings: (safetyScore / 100).clamp(0.0, 1.0),
      safetyMetricResponsiveness: level1Complete ? 0.8 : 0.2,
      safetyMetricReviews: level1Complete ? 0.6 : 0.1,
      recentReviews: const [],
    );
  }

  BackgroundConsentEntity _parseConsent(Map<String, dynamic> d) =>
      BackgroundConsentEntity(
        accepted: d['accepted'] == true,
        version: d['version'] as String? ?? '',
        acceptedAt: d['acceptedAt'] as String? ?? '',
      );

  String _levelLabel(int? level) => switch (level) {
        1 => 'level1',
        2 => 'level2',
        3 => 'level3',
        _ => 'none',
      };

  // Backend sends both a numeric `verificationLevelId` and a string
  // `verificationLevel` (e.g. 'level2'). Prefer the numeric id; fall back to
  // extracting the digit from the string form for older/other payloads.
  int? _parseLevelId(Map<String, dynamic> d) {
    final id = d['verificationLevelId'] ?? d['verification_level_id'];
    if (id is num) return id.toInt();
    final level = d['verificationLevel'] ?? d['verification_level'];
    if (level is num) return level.toInt();
    if (level is String) {
      return int.tryParse(RegExp(r'\d+').stringMatch(level) ?? '');
    }
    return null;
  }

  // 'rejected'/'declined' still went through the full Didit capture flow
  // (that's what got reviewed and rejected), so it maps to 'processing' too
  // — otherwise the status screen's checklist would wrongly show those steps
  // as incomplete.
  VerificationStep _stepFromWorkflowStatus(String status) => switch (status) {
        'approved' => VerificationStep.complete,
        'pending' ||
        'in_review' ||
        'manual_review' ||
        'rejected' ||
        'declined' =>
          VerificationStep.processing,
        _ => VerificationStep.uploadId,
      };

  // Our backend's own /verification/didit/start response — camelCase, no
  // `data` wrapper, unlike Didit's own /v3/session/ API (which our backend
  // proxies and reshapes before returning to the app).
  DiditSessionEntity _parseDiditSession(Map<String, dynamic> d) =>
      DiditSessionEntity(
        sessionId: d['sessionId']?.toString() ?? '',
        sessionToken: d['sessionToken'] as String? ?? '',
      );

  Failure _map(DioException e) => mapDioException(e);
}

