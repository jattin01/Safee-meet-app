import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/auth_response_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterParams extends Equatable {
  final String  provider;
  final String  providerToken;
  final String? name;
  final String? email;
  final String? phone;
  final String? accountType;
  final String? companyName;
  final bool    consentAccepted;

  const RegisterParams({
    required this.provider,
    required this.providerToken,
    this.name,
    this.email,
    this.phone,
    this.accountType,
    this.companyName,
    this.consentAccepted = true,
  });

  @override
  List<Object?> get props => [provider, providerToken, name, email, phone, accountType, companyName, consentAccepted];
}

class RegisterUserUseCase {
  final AuthRepository _repository;
  const RegisterUserUseCase(this._repository);

  Future<Either<Failure, AuthResponseEntity>> call(RegisterParams params) {
    if (params.providerToken.trim().isEmpty) {
      return Future.value(const Left(ValidationFailure('Provider token is required.')));
    }
    if (!params.consentAccepted) {
      return Future.value(const Left(ValidationFailure('You must accept the terms to register.')));
    }
    return _repository.register(
      provider:        params.provider,
      providerToken:   params.providerToken,
      name:            params.name?.trim(),
      email:           params.email?.trim(),
      phone:           params.phone?.trim(),
      accountType:     params.accountType,
      companyName:     params.companyName?.trim(),
      consentAccepted: params.consentAccepted,
    );
  }
}
