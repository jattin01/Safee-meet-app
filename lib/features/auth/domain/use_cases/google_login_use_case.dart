import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/auth_response_entity.dart';
import '../repositories/auth_repository.dart';

class GoogleLoginUseCase {
  final AuthRepository _repository;
  const GoogleLoginUseCase(this._repository);

  Future<Either<Failure, AuthResponseEntity>> call(String firebaseIdToken) =>
      _repository.googleLogin(firebaseIdToken: firebaseIdToken);
}
