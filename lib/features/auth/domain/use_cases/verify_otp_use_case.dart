import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../repositories/auth_repository.dart';

/// @deprecated — OTP is now verified by the provider (Firebase) before calling the backend.
/// Kept for backward compatibility with existing UI code.
class VerifyOtpUseCase {
  final AuthRepository _repository;
  const VerifyOtpUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String phone,
    required String otp,
  }) {
    if (otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
      return Future.value(
        const Left(ValidationFailure('OTP must be a 6-digit number')),
      );
    }
    // OTP verification now handled by provider at datasource level.
    // After OTP verify, frontend gets a Firebase ID token and calls login().
    return _repository.sendOtp(phone);
  }
}
