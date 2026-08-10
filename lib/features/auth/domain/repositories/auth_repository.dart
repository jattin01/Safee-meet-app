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
    String? phone,
    String? accountType,
    String? companyName,
    required bool consentAccepted,
  });

  /// Login — never creates user; returns UserNotRegisteredFailure if not found.
  Future<Either<Failure, AuthResponseEntity>> login({
    required String provider,
    required String providerToken,
    String? phone,
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
  /// Returns the OTP's validity window in seconds, if the backend sent one.
  Future<Either<Failure, int?>> sendOtp(String phone);

  /// Resends the OTP via the dedicated resend endpoint — used by "Resend
  /// OTP" on the verification screen, which never navigates away.
  Future<Either<Failure, int?>> resendOtp(String phone);

  /// Sends the initial phone OTP during registration via the dedicated
  /// registration endpoint — the login flow uses [sendOtp] instead.
  Future<Either<Failure, int?>> sendRegisterOtp(String phone);

  Future<Either<Failure, void>> sendEmailOtp(String email);

  /// Verifies a phone OTP against the backend and returns the Firebase
  /// custom token it minted — callers exchange it via
  /// FirebaseAuth.signInWithCustomToken() to get an ID token, then call
  /// login()/register() with provider: 'phone', exactly like Google/Apple.
  Future<Either<Failure, String>> verifyOtp({
    required String phone,
    required String otp,
  });
}
