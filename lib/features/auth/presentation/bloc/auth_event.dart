import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// Check stored token on app start
class AuthStatusChecked extends AuthEvent {
  const AuthStatusChecked();
}

/// Registration with any provider
class RegisterRequested extends AuthEvent {
  final String  provider;
  final String  providerToken;
  final String? name;
  final String? email;
  final String? accountType;
  final String? companyName;
  final bool    consentAccepted;

  const RegisterRequested({
    required this.provider,
    required this.providerToken,
    this.name,
    this.email,
    this.accountType,
    this.companyName,
    this.consentAccepted = true,
  });

  @override
  List<Object?> get props => [provider, providerToken, name, email, accountType, companyName, consentAccepted];
}

/// Checks whether a phone number is already registered *before* an OTP is
/// sent — so an unregistered number is rejected up front instead of after
/// the user goes through the whole OTP step.
class PhoneRegistrationCheckRequested extends AuthEvent {
  final String phone;
  const PhoneRegistrationCheckRequested(this.phone);
  @override
  List<Object?> get props => [phone];
}

/// Login with any provider token (already obtained by datasource)
class LoginRequested extends AuthEvent {
  final String provider;
  final String providerToken;

  const LoginRequested({required this.provider, required this.providerToken});

  @override
  List<Object?> get props => [provider, providerToken];
}

/// Google Sign-In: opens picker, gets Firebase token, calls backend
class GoogleLoginRequested extends AuthEvent {
  const GoogleLoginRequested();
}

/// Apple Sign-In: gets Apple token, calls backend
class AppleLoginRequested extends AuthEvent {
  const AppleLoginRequested();
}

/// Logout
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

// ── Legacy events (kept for existing UI compat) ───────────────────────────────

class SendOtpRequested extends AuthEvent {
  final String phone;
  const SendOtpRequested(this.phone);
  @override
  List<Object?> get props => [phone];
}

class OtpVerificationRequested extends AuthEvent {
  final String phone;
  final String otp;
  const OtpVerificationRequested({required this.phone, required this.otp});
  @override
  List<Object?> get props => [phone, otp];
}

class SendEmailOtpRequested extends AuthEvent {
  final String email;
  const SendEmailOtpRequested(this.email);
  @override
  List<Object?> get props => [email];
}

class EmailOtpVerificationRequested extends AuthEvent {
  final String email;
  final String otp;
  const EmailOtpVerificationRequested({required this.email, required this.otp});
  @override
  List<Object?> get props => [email, otp];
}

class RegisterStepChanged extends AuthEvent {
  final int step;
  const RegisterStepChanged(this.step);
  @override
  List<Object?> get props => [step];
}

class AuthResetRequested extends AuthEvent {
  const AuthResetRequested();
}

/// @deprecated — use GoogleLoginRequested instead
class GoogleSignInStarted extends AuthEvent {
  const GoogleSignInStarted();
}
