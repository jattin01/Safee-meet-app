import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../repositories/auth_repository.dart';

class ResendOtpUseCase {
  final AuthRepository _repository;
  ResendOtpUseCase(this._repository);

  Future<Either<Failure, int?>> call(String phone) {
    if (phone.trim().isEmpty) {
      return Future.value(const Left(ValidationFailure('Phone number is required')));
    }
    return _repository.resendOtp(phone.trim());
  }
}
