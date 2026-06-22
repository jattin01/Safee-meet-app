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

// ── Login Flow ────────────────────────────────────────────────────────────────

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

// ── Register Flow ─────────────────────────────────────────────────────────────

class RegisterStepState extends AuthState {
  final int step; // 1–6
  final String? name;
  final String? phone;
  final String? email;
  const RegisterStepState({
    required this.step,
    this.name,
    this.phone,
    this.email,
  });
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

// ── Error ─────────────────────────────────────────────────────────────────────

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}
