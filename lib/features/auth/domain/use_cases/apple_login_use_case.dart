import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/auth_response_entity.dart';
import '../repositories/auth_repository.dart';

class AppleLoginUseCase {
  final AuthRepository _repository;
  const AppleLoginUseCase(this._repository);

  Future<Either<Failure, AuthResponseEntity>> call(String appleIdToken) =>
      _repository.appleLogin(appleIdToken: appleIdToken);
}
