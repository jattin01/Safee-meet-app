import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

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

class RegisterRequested extends AuthEvent {
  final String name;
  final String phone;
  final String email;
  final String password;
  const RegisterRequested({
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
  });
  @override
  List<Object?> get props => [name, phone, email, password];
}

class SocialLoginRequested extends AuthEvent {
  final String provider;
  final String token;
  const SocialLoginRequested({required this.provider, required this.token});
  @override
  List<Object?> get props => [provider, token];
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

/// Trigger the Google Sign-In picker and authenticate via Firebase Auth.
class GoogleSignInStarted extends AuthEvent {
  const GoogleSignInStarted();
}
