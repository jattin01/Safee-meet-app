import 'package:dartz/dartz.dart';
import '../../../../core/config/app_constants.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterParams {
  final String name;
  final String phone;
  final String email;
  final String password;

  const RegisterParams({
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
  });
}

class RegisterUserUseCase {
  final AuthRepository _repository;
  RegisterUserUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call(RegisterParams params) {
    if (params.name.trim().isEmpty) {
      return Future.value(const Left(ValidationFailure('Name is required')));
    }
    if (params.email.trim().isEmpty ||
        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(params.email)) {
      return Future.value(const Left(ValidationFailure('Valid email is required')));
    }
    if (params.password.length < AppConstants.minPasswordLength) {
      return Future.value(const Left(
        ValidationFailure('Password must be at least 8 characters'),
      ));
    }
    return _repository.register(
      name: params.name.trim(),
      phone: params.phone.trim(),
      email: params.email.trim().toLowerCase(),
      password: params.password,
    );
  }
}
