import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/verification_entity.dart';

abstract class VerificationRepository {
  Future<Either<Failure, VerificationStatusEntity>> getVerificationStatus();
  Future<Either<Failure, VerificationSubmitResult>> submitVerification({
    required File faceIdImage,
    required File nationalIdFrontImage,
    required File nationalIdBackImage,
    required String nationalIdNumber,
    required String nationalIdCountry,
  });
  Future<Either<Failure, VerificationEntity>> getVerificationProgress();
}
