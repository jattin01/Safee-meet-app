import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SocialLoginUseCase {
  final AuthRepository _repository;
  SocialLoginUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call({
    required String provider,
    required String token,
  }) =>
      _repository.socialLogin(provider: provider, token: token);
}
