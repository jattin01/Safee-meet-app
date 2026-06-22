import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/verification_entity.dart';

abstract class VerificationRepository {
  Future<Either<Failure, VerificationStatusEntity>> getVerificationStatus();
  Future<Either<Failure, void>> uploadIdDocument({
    required File frontImage,
    required File backImage,
  });
  Future<Either<Failure, void>> uploadSelfie(File selfie);
  Future<Either<Failure, VerificationEntity>> getVerificationProgress();
}
