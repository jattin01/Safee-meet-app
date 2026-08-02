import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/verification_entity.dart';

abstract class VerificationRepository {
  Future<Either<Failure, VerificationStatusEntity>> getVerificationStatus();

  /// Session token for the Didit SDK's `startVerification` call — the actual
  /// ID scan + facial liveness capture happens inside Didit's native UI, not
  /// in this app.
  Future<Either<Failure, DiditSessionEntity>> createDiditSession();
}
