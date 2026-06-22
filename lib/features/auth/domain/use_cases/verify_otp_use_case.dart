import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository _repository;
  VerifyOtpUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call({
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
