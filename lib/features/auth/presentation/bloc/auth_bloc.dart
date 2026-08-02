import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/shared/failures/failures.dart';
import '../../domain/use_cases/apple_login_use_case.dart';
import '../../domain/use_cases/check_auth_status_use_case.dart';
import '../../domain/use_cases/check_user_exists_use_case.dart';
import '../../domain/use_cases/get_current_user_use_case.dart';
import '../../domain/use_cases/google_login_use_case.dart';
import '../../domain/use_cases/login_use_case.dart';
import '../../domain/use_cases/logout_use_case.dart';
import '../../domain/use_cases/register_user_use_case.dart';
import '../../domain/use_cases/send_otp_use_case.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// AuthBloc — NO Firebase logic here.
/// Firebase interaction is isolated to AuthRepositoryImpl (datasource layer).
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final CheckAuthStatusUseCase checkAuthStatus;
  final RegisterUserUseCase    registerUser;
  final LoginUseCase           login;
  final GoogleLoginUseCase     googleLogin;
  final AppleLoginUseCase      appleLogin;
  final LogoutUseCase          logout;
  final CheckUserExistsUseCase checkUserExists;
  final GetCurrentUserUseCase  getCurrentUser;
  final SendOtpUseCase         sendOtp;

  // Firebase is only here to get the ID token — not for business logic.
  // Optional: injected for testability; lazily defaults to the singletons.
  final GoogleSignIn?   _googleSignInOverride;
  final FirebaseAuth?   _firebaseAuthOverride;

  GoogleSignIn get _googleSignIn => _googleSignInOverride ?? GoogleSignIn();
  FirebaseAuth get _firebaseAuth => _firebaseAuthOverride ?? FirebaseAuth.instance;

  AuthBloc({
    required this.checkAuthStatus,
    required this.registerUser,
    required this.login,
    required this.googleLogin,
    required this.appleLogin,
    required this.logout,
    required this.checkUserExists,
    required this.getCurrentUser,
    required this.sendOtp,
    GoogleSignIn? googleSignIn,
    FirebaseAuth? firebaseAuth,
  })  : _googleSignInOverride = googleSignIn,
        _firebaseAuthOverride = firebaseAuth,
        super(const AuthInitial()) {
    on<AuthStatusChecked>(_onAuthStatusChecked);
    on<PhoneRegistrationCheckRequested>(_onCheckPhoneRegistration);
    on<RegisterRequested>(_onRegister);
    on<LoginRequested>(_onLogin);
    on<GoogleLoginRequested>(_onGoogleLogin);
    on<AppleLoginRequested>(_onAppleLogin);
    on<LogoutRequested>(_onLogout);
    // Legacy handlers
    on<SendOtpRequested>(_onSendOtp);
    on<OtpVerificationRequested>(_onVerifyOtp);
    on<SendEmailOtpRequested>(_onSendEmailOtp);
    on<EmailOtpVerificationRequested>(_onVerifyEmailOtp);
    on<RegisterStepChanged>(_onRegisterStepChanged);
    on<GoogleSignInStarted>(_onGoogleSignIn);
    on<AuthResetRequested>((_, emit) => emit(const AuthInitial()));
  }

  // ── Auth Status Check (app startup) ──────────────────────────────────────────

  Future<void> _onAuthStatusChecked(
    AuthStatusChecked event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await checkAuthStatus();
    result.fold(
      (_) => emit(const Unauthenticated()),
      (isAuth) {
        if (isAuth) {
          emit(const Authenticated());
        } else {
          emit(const Unauthenticated());
        }
      },
    );
  }

  // ── Phone registration pre-check (before OTP is sent) ─────────────────────────

  Future<void> _onCheckPhoneRegistration(
    PhoneRegistrationCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await checkUserExists(CheckUserExistsParams(phone: event.phone));
    result.fold(
      (failure) => emit(_mapFailureToState(failure)),
      (exists) => exists
          ? emit(PhoneRegistrationVerified(event.phone))
          : emit(const UserNotRegistered(
              'This mobile number is not registered. Please register first.')),
    );
  }

  // ── Registration ──────────────────────────────────────────────────────────────

  Future<void> _onRegister(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await registerUser(RegisterParams(
      provider:        event.provider,
      providerToken:   event.providerToken,
      name:            event.name,
      email:           event.email,
      accountType:     event.accountType,
      companyName:     event.companyName,
      consentAccepted: event.consentAccepted,
    ));
    result.fold(
      (failure) => emit(_mapFailureToState(failure)),
      (response) => emit(RegistrationSuccess(
        user:        response.user,
        accessToken: response.accessToken,
      )),
    );
  }

  // ── Login ─────────────────────────────────────────────────────────────────────

  Future<void> _onLogin(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await login(LoginParams(
      provider:      event.provider,
      providerToken: event.providerToken,
    ));
    result.fold(
      (failure) => emit(_mapFailureToState(failure)),
      (response) => emit(LoginSuccess(
        user:        response.user,
        accessToken: response.accessToken,
      )),
    );
  }

  // ── Google Login ──────────────────────────────────────────────────────────────

  Future<void> _onGoogleLogin(
    GoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      // Step 1: Get Firebase ID token (only here, not in business logic)
      final idToken = await _getGoogleFirebaseToken();
      if (idToken == null) {
        emit(const AuthInitial()); // user cancelled
        return;
      }

      // Step 2: Send to backend — backend validates and returns Sanctum token
      final result = await googleLogin(idToken);
      result.fold(
        (failure) => emit(_mapFailureToState(failure)),
        (response) => emit(LoginSuccess(
          user:        response.user,
          accessToken: response.accessToken,
        )),
      );
    } catch (e) {
      emit(AuthFailureState(e.toString()));
    }
  }

  // ── Apple Login ───────────────────────────────────────────────────────────────

  Future<void> _onAppleLogin(
    AppleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      // Step 1: Get Firebase ID token (only here, not in business logic)
      final idToken = await _getAppleFirebaseToken();
      if (idToken == null) {
        emit(const AuthInitial()); // user cancelled
        return;
      }

      // Step 2: Send to backend — backend validates and returns Sanctum token
      final result = await appleLogin(idToken);
      result.fold(
        (failure) => emit(_mapFailureToState(failure)),
        (response) => emit(LoginSuccess(
          user:        response.user,
          accessToken: response.accessToken,
        )),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        emit(const AuthInitial()); // user cancelled
      } else {
        emit(AuthFailureState(e.message));
      }
    } catch (e) {
      emit(AuthFailureState(e.toString()));
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────────

  Future<void> _onLogout(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await logout();
    emit(const LogoutSuccess());
  }

  // ── Google token helper ───────────────────────────────────────────────────────

  Future<String?> _getGoogleFirebaseToken() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken:     googleAuth.idToken,
    );
    final result = await _firebaseAuth.signInWithCredential(credential);
    return result.user?.getIdToken();
  }

  // ── Apple token helper ────────────────────────────────────────────────────────

  /// Apple only returns [givenName]/[familyName] on the user's very first
  /// authorization, so the display name is captured here and applied to the
  /// Firebase user immediately — it will not be available on subsequent logins.
  Future<String?> _getAppleFirebaseToken() async {
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken:  appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final result = await _firebaseAuth.signInWithCredential(oauthCredential);

    final givenName = appleCredential.givenName;
    final familyName = appleCredential.familyName;
    if (givenName != null && familyName != null) {
      await result.user?.updateDisplayName('$givenName $familyName');
    }

    return result.user?.getIdToken();
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  // ── Failure → State mapping ───────────────────────────────────────────────────

  AuthState _mapFailureToState(Failure failure) {
    if (failure is UserNotRegisteredFailure) return UserNotRegistered(failure.message);
    if (failure is UserAlreadyExistsFailure) return AuthFailureState(failure.message, code: 'USER_ALREADY_EXISTS');
    if (failure is NetworkFailure)           return AuthFailureState(failure.message, code: 'NETWORK_ERROR');
    if (failure is AccountBlockedFailure)    return AuthFailureState(failure.message, code: 'ACCOUNT_BLOCKED');
    return AuthFailureState(failure.message);
  }

  // ── Legacy handlers ───────────────────────────────────────────────────────────

  Future<void> _onSendOtp(SendOtpRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await sendOtp(event.phone);
    result.fold(
      (f) => emit(AuthError(f.message)),
      (_) => emit(OtpSent(event.phone)),
    );
  }

  Future<void> _onVerifyOtp(OtpVerificationRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    emit(const AuthInitial());
  }

  Future<void> _onSendEmailOtp(SendEmailOtpRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    emit(EmailOtpSent(event.email));
  }

  Future<void> _onVerifyEmailOtp(EmailOtpVerificationRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    emit(const EmailOtpVerified());
  }

  Future<void> _onRegisterStepChanged(RegisterStepChanged event, Emitter<AuthState> emit) async {
    final s = state is RegisterStepState ? state as RegisterStepState : null;
    emit(RegisterStepState(
      step: event.step,
      name: s?.name,
      phone: s?.phone,
      email: s?.email,
    ));
  }

  Future<void> _onGoogleSignIn(GoogleSignInStarted _, Emitter<AuthState> emit) async {
    add(const GoogleLoginRequested());
  }
}
