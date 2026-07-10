import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Valid token found on startup
class Authenticated extends AuthState {
  final UserEntity? user;
  const Authenticated({this.user});
  @override
  List<Object?> get props => [user];
}

/// No valid token
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// POST /auth/register succeeded
class RegistrationSuccess extends AuthState {
  final UserEntity user;
  final String accessToken;
  const RegistrationSuccess({required this.user, required this.accessToken});
  @override
  List<Object?> get props => [user, accessToken];
}

/// POST /auth/login succeeded
class LoginSuccess extends AuthState {
  final UserEntity user;
  final String accessToken;
  const LoginSuccess({required this.user, required this.accessToken});
  @override
  List<Object?> get props => [user, accessToken];
}

/// Logout completed
class LogoutSuccess extends AuthState {
  const LogoutSuccess();
}

/// Backend returned USER_NOT_REGISTERED
class UserNotRegistered extends AuthState {
  final String message;
  const UserNotRegistered([this.message = 'You are not registered right now. Please register yourself first.']);
  @override
  List<Object?> get props => [message];
}

/// Any auth error
class AuthFailureState extends AuthState {
  final String message;
  final String? code;
  const AuthFailureState(this.message, {this.code});
  @override
  List<Object?> get props => [message, code];
}

// ── Legacy states (kept for existing UI compat) ───────────────────────────────

class OtpSent extends AuthState {
  final String phone;
  const OtpSent(this.phone);
  @override
  List<Object?> get props => [phone];
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class RegisterStepState extends AuthState {
  final int step;
  final String? name;
  final String? phone;
  final String? email;
  const RegisterStepState({required this.step, this.name, this.phone, this.email});
  @override
  List<Object?> get props => [step, name, phone, email];
}

class MobileOtpSent extends AuthState {
  final String phone;
  const MobileOtpSent(this.phone);
  @override
  List<Object?> get props => [phone];
}

class MobileOtpVerified extends AuthState {
  const MobileOtpVerified();
}

class EmailOtpSent extends AuthState {
  final String email;
  const EmailOtpSent(this.email);
  @override
  List<Object?> get props => [email];
}

class EmailOtpVerified extends AuthState {
  const EmailOtpVerified();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}
