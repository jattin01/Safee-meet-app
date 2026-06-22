import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:safee_meet/core/shared/failures/failures.dart';
import 'package:safee_meet/features/auth/domain/entities/user_entity.dart';
import 'package:safee_meet/features/auth/domain/use_cases/register_user_use_case.dart';
import 'package:safee_meet/features/auth/domain/use_cases/send_otp_use_case.dart';
import 'package:safee_meet/features/auth/domain/use_cases/social_login_use_case.dart';
import 'package:safee_meet/features/auth/domain/use_cases/verify_otp_use_case.dart';
import 'package:safee_meet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:safee_meet/features/auth/presentation/bloc/auth_event.dart';
import 'package:safee_meet/features/auth/presentation/bloc/auth_state.dart';

class MockSendOtpUseCase extends Mock implements SendOtpUseCase {}
class MockVerifyOtpUseCase extends Mock implements VerifyOtpUseCase {}
class MockRegisterUserUseCase extends Mock implements RegisterUserUseCase {}
class MockSocialLoginUseCase extends Mock implements SocialLoginUseCase {}

final _user = UserEntity(
  id: '1',
  name: 'John Doe',
  phone: '+1234567890',
  email: 'john@example.com',
  safeePin: 'SM-ABC123',
  trustScore: 85,
  verificationLevel: 'level1',
  plan: 'free',
  safetyRating: 4.5,
  meetingsCompleted: 10,
);

void main() {
  late MockSendOtpUseCase sendOtp;
  late MockVerifyOtpUseCase verifyOtp;
  late MockRegisterUserUseCase registerUser;
  late MockSocialLoginUseCase socialLogin;

  setUp(() {
    sendOtp = MockSendOtpUseCase();
    verifyOtp = MockVerifyOtpUseCase();
    registerUser = MockRegisterUserUseCase();
    socialLogin = MockSocialLoginUseCase();

    registerFallbackValue(const RegisterParams(
      name: '',
      phone: '',
      email: '',
      password: '',
    ));
  });

  AuthBloc _bloc() => AuthBloc(
        sendOtp: sendOtp,
        verifyOtp: verifyOtp,
        registerUser: registerUser,
        socialLogin: socialLogin,
      );

  group('SendOtpRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, OtpSent] on success',
      build: _bloc,
      setUp: () {
        when(() => sendOtp(any())).thenAnswer((_) async => const Right(null));
      },
      act: (bloc) => bloc.add(const SendOtpRequested('+1234567890')),
      expect: () => [
        const AuthLoading(),
        const OtpSent('+1234567890'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] on network failure',
      build: _bloc,
      setUp: () {
        when(() => sendOtp(any()))
            .thenAnswer((_) async => const Left(NetworkFailure()));
      },
      act: (bloc) => bloc.add(const SendOtpRequested('+1234567890')),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
      ],
    );
  });

  group('OtpVerificationRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on success',
      build: _bloc,
      setUp: () {
        when(() => verifyOtp(phone: any(named: 'phone'), otp: any(named: 'otp')))
            .thenAnswer((_) async => Right(_user));
      },
      act: (bloc) => bloc.add(const OtpVerificationRequested(
        phone: '+1234567890',
        otp: '123456',
      )),
      expect: () => [
        const AuthLoading(),
        AuthAuthenticated(_user),
      ],
    );
  });

  group('RegisterRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on success',
      build: _bloc,
      setUp: () {
        when(() => registerUser(any())).thenAnswer((_) async => Right(_user));
      },
      act: (bloc) => bloc.add(const RegisterRequested(
        name: 'John Doe',
        phone: '+1234567890',
        email: 'john@example.com',
        password: 'Password@1',
      )),
      expect: () => [
        const AuthLoading(),
        AuthAuthenticated(_user),
      ],
    );
  });

  group('AuthResetRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthInitial]',
      build: _bloc,
      act: (bloc) => bloc.add(const AuthResetRequested()),
      expect: () => [const AuthInitial()],
    );
  });
}
