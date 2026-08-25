import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
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
import '../../domain/use_cases/resend_otp_use_case.dart';
import '../../domain/use_cases/send_otp_use_case.dart';
import '../../domain/use_cases/send_register_otp_use_case.dart';
import '../../domain/use_cases/verify_otp_use_case.dart';
import '../../domain/use_cases/delete_account_use_case.dart';
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
  final ResendOtpUseCase       resendOtp;
  final SendRegisterOtpUseCase sendRegisterOtp;
  final VerifyOtpUseCase       verifyOtp;
  final DeleteAccountUseCase   deleteAccountUseCase;

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
    required this.resendOtp,
    required this.sendRegisterOtp,
    required this.verifyOtp,
    required this.deleteAccountUseCase,
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
    on<DeleteAccountRequested>(_onDeleteAccount);
    // Legacy handlers
    on<SendOtpRequested>(_onSendOtp);
    on<ResendOtpRequested>(_onResendOtp);
    on<SendRegisterOtpRequested>(_onSendRegisterOtp);
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
      phone:           event.phone,
      accountType:     event.accountType,
      companyName:     event.companyName,
      consentAccepted: event.consentAccepted,
    ));
    result.fold(
      (failure) => emit(_mapFailureToState(failure)),
      (response) => emit(RegistrationSuccess(
        user:        response.user,
        accessToken: response.accessToken,
        isNewUser:   response.isNewUser,
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
      phone:         event.phone,
    ));
    result.fold(
      (failure) => emit(_mapFailureToState(failure)),
      (response) => emit(LoginSuccess(
        user:        response.user,
        accessToken: response.accessToken,
        isNewUser:   response.isNewUser,
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

      // Backend requires a verified phone on every /login call — hand off
      // to the UI's phone-OTP flow instead of logging in directly.
      emit(SocialTokenObtained(provider: 'google', providerToken: idToken));
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

      // Backend requires a verified phone on every /login call — hand off
      // to the UI's phone-OTP flow instead of logging in directly.
      emit(SocialTokenObtained(provider: 'apple', providerToken: idToken));
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

  // ── Delete Account ────────────────────────────────────────────────────────────

  Future<void> _onDeleteAccount(
    DeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await deleteAccountUseCase();
    result.fold(
      (failure) => emit(_mapFailureToState(failure)),
      (_) => emit(const LogoutSuccess()),
    );
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

  // ── Phone OTP (backend-verified, replaces Firebase phone auth) ───────────────

  Future<void> _onSendOtp(SendOtpRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await sendOtp(event.phone);
    result.fold(
      (f) => emit(_mapFailureToState(f)),
      (expiresIn) => emit(OtpSent(event.phone, expiresIn)),
    );
  }

  Future<void> _onResendOtp(ResendOtpRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await resendOtp(event.phone);
    result.fold(
      (f) => emit(_mapFailureToState(f)),
      (expiresIn) => emit(OtpResent(event.phone, expiresIn)),
    );
  }

  Future<void> _onSendRegisterOtp(SendRegisterOtpRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await sendRegisterOtp(event.phone);
    result.fold(
      (f) => emit(_mapFailureToState(f)),
      (expiresIn) => emit(OtpSent(event.phone, expiresIn)),
    );
  }

  Future<void> _onVerifyOtp(OtpVerificationRequested event, Emitter<AuthState> emit) async {
    // Debug-only timing instrumentation — verify-otp itself is fast; the
    // real cost here tends to be the two Firebase network round trips
    // (signInWithCustomToken, then getIdToken) that happen between our
    // backend confirming the OTP and PhoneOtpVerified reaching the UI.
    // Safe to remove once confirmed.
    final sw = kDebugMode ? (Stopwatch()..start()) : null;
    void mark(String label) {
      if (sw != null) {
        // ignore: avoid_print
        print('[TIMING] $label: ${sw.elapsedMilliseconds}ms');
      }
    }

    emit(const AuthLoading());
    final result = await verifyOtp(phone: event.phone, otp: event.otp);
    mark('POST /auth/verify-otp responded');
    await result.fold(
      (failure) async => emit(_mapFailureToState(failure)),
      (customToken) async {
        try {
          final cred = await _firebaseAuth.signInWithCustomToken(customToken);
          mark('Firebase signInWithCustomToken done');
          final idToken = await cred.user?.getIdToken();
          mark('Firebase getIdToken done');
          if (idToken == null) {
            emit(const AuthFailureState('Could not verify OTP. Please try again.'));
            return;
          }
          emit(PhoneOtpVerified(idToken));
          mark('PhoneOtpVerified emitted');
        } on FirebaseAuthException catch (e) {
          emit(AuthFailureState(e.message ?? 'Could not verify OTP. Please try again.'));
        }
      },
    );
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
