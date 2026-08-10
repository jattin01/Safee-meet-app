import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/auth_response_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;
  const LoginUseCase(this._repository);

  Future<Either<Failure, AuthResponseEntity>> call(LoginParams params) =>
      _repository.login(
        provider: params.provider,
        providerToken: params.providerToken,
        phone: params.phone,
      );
}

class LoginParams extends Equatable {
  final String provider;
  final String providerToken;
  final String? phone;

  const LoginParams({required this.provider, required this.providerToken, this.phone});

  @override
  List<Object?> get props => [provider, providerToken, phone];
}
