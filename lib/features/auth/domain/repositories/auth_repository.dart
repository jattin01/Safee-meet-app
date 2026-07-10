import 'package:dartz/dartz.dart';
import '../../../../core/shared/failures/failures.dart';
import '../entities/auth_response_entity.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Registration — creates user only if not existing.
  Future<Either<Failure, AuthResponseEntity>> register({
    required String provider,
    required String providerToken,
    String? name,
    String? email,
    String? accountType,
    String? companyName,
    required bool consentAccepted,
  });

  /// Login — never creates user; returns UserNotRegisteredFailure if not found.
  Future<Either<Failure, AuthResponseEntity>> login({
    required String provider,
    required String providerToken,
  });

  /// Google sign-in token → backend login (never registers).
  Future<Either<Failure, AuthResponseEntity>> googleLogin({
    required String firebaseIdToken,
  });

  /// Apple sign-in token → backend login (never registers).
  Future<Either<Failure, AuthResponseEntity>> appleLogin({
    required String appleIdToken,
  });

  /// Logout — invalidates server token + clears local session.
  Future<Either<Failure, void>> logout();

  /// Pre-flight check — does this identity exist on the backend?
  Future<Either<Failure, bool>> checkUserExists({
    String? email,
    String? phone,
    String? providerUid,
  });

  /// Returns cached/live current user or failure.
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Returns true if a valid access token is stored locally.
  Future<Either<Failure, bool>> checkAuthStatus();

  // Legacy OTP methods (kept for backward compat)
  Future<Either<Failure, void>> sendOtp(String phone);
  Future<Either<Failure, void>> sendEmailOtp(String email);
}
