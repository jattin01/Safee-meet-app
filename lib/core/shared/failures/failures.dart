import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// ── Network ───────────────────────────────────────────────────────────────────

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection. Please check your network.']);
}

// ── Server ────────────────────────────────────────────────────────────────────

class ServerFailure extends Failure {
  final int? statusCode;
  final String? code;
  const ServerFailure(super.message, {this.statusCode, this.code});

  @override
  List<Object> get props => [message, statusCode ?? 0, code ?? ''];
}

// ── Auth — Typed Failures (map to backend error codes) ───────────────────────

/// USER_NOT_REGISTERED
class UserNotRegisteredFailure extends Failure {
  const UserNotRegisteredFailure([
    super.message =
        'You are not registered right now. Please register yourself first.',
  ]);
}

/// USER_ALREADY_EXISTS
class UserAlreadyExistsFailure extends Failure {
  const UserAlreadyExistsFailure([
    super.message = 'This account already exists. Please login.',
  ]);
}

/// INVALID_CREDENTIALS
class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure([super.message = 'Invalid credentials provided.']);
}

/// ACCOUNT_BLOCKED
class AccountBlockedFailure extends Failure {
  const AccountBlockedFailure([
    super.message = 'Your account has been blocked. Please contact support.',
  ]);
}

/// ACCOUNT_INACTIVE
class AccountInactiveFailure extends Failure {
  const AccountInactiveFailure([super.message = 'Your account is not active.']);
}

/// PHONE_VERIFICATION_FAILED
class PhoneVerificationFailure extends Failure {
  const PhoneVerificationFailure([super.message = 'Phone verification failed.']);
}

/// EMAIL_VERIFICATION_FAILED
class EmailVerificationFailure extends Failure {
  const EmailVerificationFailure([super.message = 'Email verification failed.']);
}

/// SOCIAL_VALIDATION_FAILED
class SocialValidationFailure extends Failure {
  const SocialValidationFailure([super.message = 'Social authentication failed.']);
}

/// UNAUTHORIZED
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Session expired. Please login again.']);
}

/// VALIDATION_ERROR
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

// ── Generic ───────────────────────────────────────────────────────────────────

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local data error.']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}

// Backward compat alias
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed.']);
}
