import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/verification_entity.dart';

abstract class VerificationRepository {
  Future<Either<Failure, VerificationStatusEntity>> getVerificationStatus();

  /// Session token for the Didit SDK's `startVerification` call — the actual
  /// ID scan + facial liveness capture happens inside Didit's native UI, not
  /// in this app.
  Future<Either<Failure, DiditSessionEntity>> createDiditSession();

  /// Calls POST /v1/verification/background-consent and validates the response.
  /// On success, persists acceptance locally so the consent popup is skipped
  /// on subsequent taps.
  Future<Either<Failure, BackgroundConsentEntity>> submitBackgroundConsent();

  /// Checks whether the user has already accepted the background-check consent
  /// (reads from local secure storage — no network call).
  Future<bool> hasBackgroundConsent();
}
