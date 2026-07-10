import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:safee_meet/core/shared/failures/failures.dart';
import 'package:safee_meet/features/auth/domain/entities/auth_response_entity.dart';
import 'package:safee_meet/features/auth/domain/entities/user_entity.dart';
import 'package:safee_meet/features/auth/domain/use_cases/apple_login_use_case.dart';
import 'package:safee_meet/features/auth/domain/use_cases/check_auth_status_use_case.dart';
import 'package:safee_meet/features/auth/domain/use_cases/check_user_exists_use_case.dart';
import 'package:safee_meet/features/auth/domain/use_cases/get_current_user_use_case.dart';
import 'package:safee_meet/features/auth/domain/use_cases/google_login_use_case.dart';
import 'package:safee_meet/features/auth/domain/use_cases/login_use_case.dart';
import 'package:safee_meet/features/auth/domain/use_cases/logout_use_case.dart';
import 'package:safee_meet/features/auth/domain/use_cases/register_user_use_case.dart';
import 'package:safee_meet/features/auth/domain/use_cases/send_otp_use_case.dart';
import 'package:safee_meet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:safee_meet/features/auth/presentation/bloc/auth_event.dart';
import 'package:safee_meet/features/auth/presentation/bloc/auth_state.dart';

class MockCheckAuthStatusUseCase extends Mock implements CheckAuthStatusUseCase {}
class MockRegisterUserUseCase extends Mock implements RegisterUserUseCase {}
class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockGoogleLoginUseCase extends Mock implements GoogleLoginUseCase {}
class MockAppleLoginUseCase extends Mock implements AppleLoginUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockCheckUserExistsUseCase extends Mock implements CheckUserExistsUseCase {}
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}
class MockSendOtpUseCase extends Mock implements SendOtpUseCase {}

final _user = UserEntity(
  id: 'ulid-123',
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

final _authResponse = AuthResponseEntity(
  accessToken:  'sanctum-token-123',
  refreshToken: null,
  user: _user,
);

void main() {
  late MockCheckAuthStatusUseCase checkAuthStatus;
  late MockRegisterUserUseCase    registerUser;
  late MockLoginUseCase           login;
  late MockGoogleLoginUseCase     googleLogin;
  late MockAppleLoginUseCase      appleLogin;
  late MockLogoutUseCase          logout;
  late MockCheckUserExistsUseCase checkUserExists;
  late MockGetCurrentUserUseCase  getCurrentUser;
  late MockSendOtpUseCase         sendOtp;

  setUp(() {
    checkAuthStatus = MockCheckAuthStatusUseCase();
    registerUser    = MockRegisterUserUseCase();
    login           = MockLoginUseCase();
    googleLogin     = MockGoogleLoginUseCase();
    appleLogin      = MockAppleLoginUseCase();
    logout          = MockLogoutUseCase();
    checkUserExists = MockCheckUserExistsUseCase();
    getCurrentUser  = MockGetCurrentUserUseCase();
    sendOtp         = MockSendOtpUseCase();

    registerFallbackValue(const RegisterParams(
      provider:      'phone',
      providerToken: 'firebase-id-token',
    ));
    registerFallbackValue(const LoginParams(
      provider:      'phone',
      providerToken: 'firebase-id-token',
    ));
    registerFallbackValue(const CheckUserExistsParams());
  });

  AuthBloc _bloc() => AuthBloc(
        checkAuthStatus: checkAuthStatus,
        registerUser:    registerUser,
        login:           login,
        googleLogin:     googleLogin,
        appleLogin:      appleLogin,
        logout:          logout,
        checkUserExists: checkUserExists,
        getCurrentUser:  getCurrentUser,
        sendOtp:         sendOtp,
      );

  // ── AuthStatusChecked ──────────────────────────────────────────────────────

  group('AuthStatusChecked', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when token exists',
      build: _bloc,
      setUp: () {
        when(() => checkAuthStatus()).thenAnswer((_) async => const Right(true));
      },
      act: (bloc) => bloc.add(const AuthStatusChecked()),
      expect: () => [const AuthLoading(), const Authenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] when no token',
      build: _bloc,
      setUp: () {
        when(() => checkAuthStatus()).thenAnswer((_) async => const Right(false));
      },
      act: (bloc) => bloc.add(const AuthStatusChecked()),
      expect: () => [const AuthLoading(), const Unauthenticated()],
    );
  });

  // ── RegisterRequested ──────────────────────────────────────────────────────

  group('RegisterRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, RegistrationSuccess] on success',
      build: _bloc,
      setUp: () {
        when(() => registerUser(any())).thenAnswer((_) async => Right(_authResponse));
      },
      act: (bloc) => bloc.add(const RegisterRequested(
        provider:      'phone',
        providerToken: 'firebase-id-token',
        name:          'John Doe',
      )),
      expect: () => [
        const AuthLoading(),
        isA<RegistrationSuccess>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailureState] when USER_ALREADY_EXISTS',
      build: _bloc,
      setUp: () {
        when(() => registerUser(any()))
            .thenAnswer((_) async => const Left(UserAlreadyExistsFailure('User already registered.')));
      },
      act: (bloc) => bloc.add(const RegisterRequested(
        provider:      'phone',
        providerToken: 'firebase-id-token',
      )),
      expect: () => [
        const AuthLoading(),
        isA<AuthFailureState>(),
      ],
    );
  });

  // ── LoginRequested ─────────────────────────────────────────────────────────

  group('LoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, LoginSuccess] on success',
      build: _bloc,
      setUp: () {
        when(() => login(any())).thenAnswer((_) async => Right(_authResponse));
      },
      act: (bloc) => bloc.add(const LoginRequested(
        provider:      'phone',
        providerToken: 'firebase-id-token',
      )),
      expect: () => [
        const AuthLoading(),
        isA<LoginSuccess>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, UserNotRegistered] on USER_NOT_REGISTERED',
      build: _bloc,
      setUp: () {
        when(() => login(any()))
            .thenAnswer((_) async => const Left(UserNotRegisteredFailure('Not registered.')));
      },
      act: (bloc) => bloc.add(const LoginRequested(
        provider:      'google',
        providerToken: 'google-firebase-token',
      )),
      expect: () => [
        const AuthLoading(),
        isA<UserNotRegistered>(),
      ],
    );
  });

  // ── LogoutRequested ────────────────────────────────────────────────────────

  group('LogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, LogoutSuccess]',
      build: _bloc,
      setUp: () {
        when(() => logout()).thenAnswer((_) async => const Right(null));
      },
      act: (bloc) => bloc.add(const LogoutRequested()),
      expect: () => [const AuthLoading(), const LogoutSuccess()],
    );
  });

  // ── SendOtpRequested ───────────────────────────────────────────────────────

  group('SendOtpRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, OtpSent] on success',
      build: _bloc,
      setUp: () {
        when(() => sendOtp(any())).thenAnswer((_) async => const Right(null));
      },
      act: (bloc) => bloc.add(const SendOtpRequested('+1234567890')),
      expect: () => [const AuthLoading(), const OtpSent('+1234567890')],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] on network failure',
      build: _bloc,
      setUp: () {
        when(() => sendOtp(any()))
            .thenAnswer((_) async => const Left(NetworkFailure()));
      },
      act: (bloc) => bloc.add(const SendOtpRequested('+1234567890')),
      expect: () => [const AuthLoading(), isA<AuthError>()],
    );
  });

  // ── AuthResetRequested ─────────────────────────────────────────────────────

  group('AuthResetRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthInitial]',
      build: _bloc,
      act: (bloc) => bloc.add(const AuthResetRequested()),
      expect: () => [const AuthInitial()],
    );
  });
}
