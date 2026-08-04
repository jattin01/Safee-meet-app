import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../repositories/auth_repository.dart';

/// Verifies a phone OTP against the backend (new SMS provider) and returns
/// the Firebase custom token it minted for that phone's uid.
class VerifyOtpUseCase {
  final AuthRepository _repository;
  const VerifyOtpUseCase(this._repository);

  Future<Either<Failure, String>> call({
    required String phone,
    required String otp,
  }) {
    if (otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
      return Future.value(
        const Left(ValidationFailure('OTP must be a 6-digit number')),
      );
    }
    return _repository.verifyOtp(phone: phone, otp: otp);
  }
}
