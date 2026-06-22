import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/shared/failures/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../local_data_sources/auth_local_data_source.dart';
import '../remote_data_sources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  AuthRepositoryImpl(this._remote, this._local);

  @override
  Future<Either<Failure, void>> sendOtp(String phone) async {
    try {
      await _remote.sendOtp(phone);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final model = await _remote.verifyOtp(phone: phone, otp: otp);
      await _local.cacheUser(model);
      return Right(model.toEntity());
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> sendEmailOtp(String email) async {
    try {
      await _remote.sendEmailOtp(email);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    try {
      await _remote.verifyEmailOtp(email: email, otp: otp);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      final model = await _remote.register(
        name: name,
        phone: phone,
        email: email,
        password: password,
      );
      await _local.cacheUser(model);
      return Right(model.toEntity());
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> socialLogin({
    required String provider,
    required String token,
  }) async {
    try {
      final model = await _remote.socialLogin(provider: provider, token: token);
      await _local.cacheUser(model);
      return Right(model.toEntity());
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final model = await _remote.getCurrentUser();
      return Right(model.toEntity());
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remote.logout();
      await _local.clearAll();
      return const Right(null);
    } on DioException catch (e) {
      // Still clear local session even if remote call fails
      await _local.clearAll();
      return Left(_mapDioError(e));
    } catch (_) {
      await _local.clearAll();
      return const Left(UnknownFailure());
    }
  }

  Failure _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.unknown) {
      return const NetworkFailure();
    }
    final status = e.response?.statusCode;
    if (status == 401) return const AuthFailure('Invalid credentials');
    if (status == 422) {
      final msg =
          e.response?.data?['message'] as String? ?? 'Validation failed';
      return ValidationFailure(msg);
    }
    return ServerFailure(
      e.response?.data?['message'] as String? ?? 'Server error',
      statusCode: status,
    );
  }
}
