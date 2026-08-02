import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/shared/failures/dio_failure_mapper.dart';
import '../../../../core/shared/failures/failures.dart';
import '../../../../core/storage/auth_session_manager.dart';
import '../../domain/entities/auth_response_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../local_data_sources/auth_local_data_source.dart';
import '../remote_data_sources/auth_remote_data_source.dart';

/// All Firebase interaction is ONLY in this file.
/// BLoC / UseCases / UI never touch Firebase directly.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource  _remote;
  final AuthLocalDataSource   _local;
  final AuthSessionManager    _session;
  final SecureStorageService  _secureStorage;
  final GoogleSignIn          _googleSignIn;
  final FirebaseAuth          _firebaseAuth;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource  local,
    required AuthSessionManager   session,
    required SecureStorageService secureStorage,
    GoogleSignIn?   googleSignIn,
    FirebaseAuth?   firebaseAuth,
  })  : _remote        = remote,
        _local         = local,
        _session       = session,
        _secureStorage = secureStorage,
        _googleSignIn  = googleSignIn ?? GoogleSignIn(),
        _firebaseAuth  = firebaseAuth ?? FirebaseAuth.instance;

  // ── Registration ────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, AuthResponseEntity>> register({
    required String provider,
    required String providerToken,
    String? name,
    String? email,
    String? accountType,
    String? companyName,
    required bool consentAccepted,
  }) async {
    try {
      final model = await _remote.register(
        provider:        provider,
        providerToken:   providerToken,
        name:            name,
        email:           email,
        accountType:     accountType,
        companyName:     companyName,
        consentAccepted: consentAccepted,
      );
      final entity = model.toEntity();
      await _session.saveSession(
        accessToken:  entity.accessToken,
        refreshToken: entity.refreshToken,
        userId:       entity.user.id,
      );
      await _local.cacheUser(model.user);
      if (entity.user.displayName != null) {
        await _secureStorage.saveUserName(entity.user.displayName!);
      }
      final phone = _firebaseAuth.currentUser?.phoneNumber;
      if (phone != null) await _secureStorage.saveUserPhone(phone);
      return Right(entity);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  // ── Login ───────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, AuthResponseEntity>> login({
    required String provider,
    required String providerToken,
  }) async {
    try {
      final model  = await _remote.login(provider: provider, providerToken: providerToken);
      final entity = model.toEntity();
      await _session.saveSession(
        accessToken:  entity.accessToken,
        refreshToken: entity.refreshToken,
        userId:       entity.user.id,
      );
      try {
        await _local.cacheUser(model.user);
        if (entity.user.displayName != null) {
          await _secureStorage.saveUserName(entity.user.displayName!);
        }
        final phone = _firebaseAuth.currentUser?.phoneNumber;
        if (phone != null) await _secureStorage.saveUserPhone(phone);
      } catch (_) {}
      return Right(entity);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e, st) {
      // ignore: avoid_print
      print('[AuthRepo.login] $e\n$st');
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ── Google Login (gets Firebase token → calls backend login) ────────────────

  @override
  Future<Either<Failure, AuthResponseEntity>> googleLogin({
    required String firebaseIdToken,
  }) async {
    // Firebase is ONLY used here to get the ID token.
    // The backend validates it and issues its own Sanctum token.
    return login(provider: 'google', providerToken: firebaseIdToken);
  }

  // ── Apple Login ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, AuthResponseEntity>> appleLogin({
    required String appleIdToken,
  }) async {
    return login(provider: 'apple', providerToken: appleIdToken);
  }

  // ── Logout ───────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remote.logout();
    } on DioException {
      // Proceed even if server call fails
    }
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
    } catch (_) {}
    await _session.clearSession();
    await _local.clearAll();
    return const Right(null);
  }

  // ── Check User Exists ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, bool>> checkUserExists({
    String? email,
    String? phone,
    String? providerUid,
  }) async {
    try {
      final exists = await _remote.checkUserExists(
        email: email,
        phone: phone,
        providerUid: providerUid,
      );
      return Right(exists);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  // ── Get Current User ──────────────────────────────────────────────────────────

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

  // ── Check Auth Status ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, bool>> checkAuthStatus() async {
    try {
      final isAuth = await _session.isAuthenticated();
      return Right(isAuth);
    } catch (_) {
      return const Right(false);
    }
  }

  // ── Legacy OTP stubs ──────────────────────────────────────────────────────────

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

  // ── Error Mapping ─────────────────────────────────────────────────────────────

  Failure _mapDioError(DioException e) {
    if (isConnectivityError(e)) return const NetworkFailure();

    final status  = e.response?.statusCode;
    final body    = e.response?.data as Map<String, dynamic>?;
    final code    = body?['code']    as String?;
    final message = body?['message'] as String? ?? 'An error occurred.';

    return switch (code) {
      'USER_NOT_REGISTERED'       => UserNotRegisteredFailure(message),
      'USER_ALREADY_EXISTS'       => UserAlreadyExistsFailure(message),
      'INVALID_CREDENTIALS'       => InvalidCredentialsFailure(message),
      'ACCOUNT_BLOCKED'           => AccountBlockedFailure(message),
      'ACCOUNT_INACTIVE'          => AccountInactiveFailure(message),
      'PHONE_VERIFICATION_FAILED' => PhoneVerificationFailure(message),
      'EMAIL_VERIFICATION_FAILED' => EmailVerificationFailure(message),
      'SOCIAL_VALIDATION_FAILED'  => SocialValidationFailure(message),
      'UNAUTHORIZED'              => UnauthorizedFailure(message),
      'VALIDATION_ERROR'          => ValidationFailure(message),
      _                           => ServerFailure(message, statusCode: status, code: code),
    };
  }
}
