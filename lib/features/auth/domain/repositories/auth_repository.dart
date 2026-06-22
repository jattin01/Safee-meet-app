import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> sendOtp(String phone);
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String phone,
    required String otp,
  });
  Future<Either<Failure, void>> sendEmailOtp(String email);
  Future<Either<Failure, void>> verifyEmailOtp({
    required String email,
    required String otp,
  });
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  });
  Future<Either<Failure, UserEntity>> socialLogin({
    required String provider, // 'google' | 'apple'
    required String token,
  });
  Future<Either<Failure, UserEntity>> getCurrentUser();
  Future<Either<Failure, void>> logout();
}
