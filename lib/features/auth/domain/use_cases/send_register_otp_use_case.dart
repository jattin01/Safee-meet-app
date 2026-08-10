import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../repositories/auth_repository.dart';

class SendRegisterOtpUseCase {
  final AuthRepository _repository;
  SendRegisterOtpUseCase(this._repository);

  Future<Either<Failure, int?>> call(String phone) {
    if (phone.trim().isEmpty) {
      return Future.value(const Left(ValidationFailure('Phone number is required')));
    }
    return _repository.sendRegisterOtp(phone.trim());
  }
}
