import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/auth_response_entity.dart';
import '../repositories/auth_repository.dart';

/// @deprecated — use GoogleLoginUseCase or AppleLoginUseCase instead.
class SocialLoginUseCase {
  final AuthRepository _repository;
  const SocialLoginUseCase(this._repository);

  Future<Either<Failure, AuthResponseEntity>> call({
    required String provider,
    required String token,
  }) =>
      _repository.login(provider: provider, providerToken: token);
}
