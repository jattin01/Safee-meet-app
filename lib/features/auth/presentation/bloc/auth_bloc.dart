import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/services/google_auth_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/use_cases/register_user_use_case.dart';
import '../../domain/use_cases/send_otp_use_case.dart';
import '../../domain/use_cases/social_login_use_case.dart';
import '../../domain/use_cases/verify_otp_use_case.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SendOtpUseCase sendOtp;
  final VerifyOtpUseCase verifyOtp;
  final RegisterUserUseCase registerUser;
  final SocialLoginUseCase socialLogin;
  final GoogleAuthService googleAuthService;
  final SecureStorageService session;
  final FcmService fcmService;

  AuthBloc({
    required this.sendOtp,
    required this.verifyOtp,
    required this.registerUser,
    required this.socialLogin,
    required this.googleAuthService,
    required this.session,
    required this.fcmService,
  }) : super(const AuthInitial()) {
    on<SendOtpRequested>(_onSendOtp);
    on<OtpVerificationRequested>(_onVerifyOtp);
    on<SendEmailOtpRequested>(_onSendEmailOtp);
    on<EmailOtpVerificationRequested>(_onVerifyEmailOtp);
    on<RegisterRequested>(_onRegister);
    on<SocialLoginRequested>(_onSocialLogin);
    on<GoogleSignInStarted>(_onGoogleSignIn);
    on<RegisterStepChanged>(_onRegisterStepChanged);
    on<AuthResetRequested>((_, emit) => emit(const AuthInitial()));
  }

  Future<void> _onSendOtp(
    SendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await sendOtp(event.phone);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(OtpSent(event.phone)),
    );
  }

  Future<void> _onVerifyOtp(
    OtpVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await verifyOtp(phone: event.phone, otp: event.otp);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSendEmailOtp(
    SendEmailOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    emit(EmailOtpSent(event.email));
  }

  Future<void> _onVerifyEmailOtp(
    EmailOtpVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    emit(const EmailOtpVerified());
  }

  Future<void> _onRegister(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await registerUser(
      RegisterParams(
        name: event.name,
        phone: event.phone,
        email: event.email,
        password: event.password,
      ),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSocialLogin(
    SocialLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await socialLogin(
      provider: event.provider,
      token: event.token,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  /// Runs the Google account picker → Firebase credential exchange.
  /// On success, saves the Firebase UID and emits [AuthAuthenticated].
  /// On cancel (user dismissed picker), returns to [AuthInitial].
  Future<void> _onGoogleSignIn(
    GoogleSignInStarted _,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final firebaseUser = await googleAuthService.signIn();

      if (firebaseUser == null) {
        // User dismissed the picker — reset without showing an error
        emit(const AuthInitial());
        return;
      }

      final idToken = await firebaseUser.getIdToken();
      if (idToken != null && idToken.isNotEmpty) {
        await session.saveAccessToken(idToken);
      }

      // Persist the Firebase UID + display name for use across the app
      await session.saveUserId(firebaseUser.uid);
      await session.saveUserName(firebaseUser.displayName ?? 'SAFEE User');

      // Upsert profile in Firestore so other users can find and chat with this user
      await googleAuthService.saveUserProfile(firebaseUser);

      // Initialize FCM: request permission, save token, set up handlers
      await fcmService.initialize();

      final user = UserEntity(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'SAFEE User',
        email: firebaseUser.email ?? '',
        phone: firebaseUser.phoneNumber ?? '',
        safeePin: '',
        trustScore: 0,
        verificationLevel: 'none',
        plan: 'free',
        avatarUrl: firebaseUser.photoURL,
        safetyRating: 0.0,
        meetingsCompleted: 0,
      );

      emit(AuthAuthenticated(user));
    } on Exception catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onRegisterStepChanged(
    RegisterStepChanged event,
    Emitter<AuthState> emit,
  ) {
    if (state is RegisterStepState) {
      final s = state as RegisterStepState;
      emit(RegisterStepState(
        step: event.step,
        name: s.name,
        phone: s.phone,
        email: s.email,
      ));
    } else {
      emit(RegisterStepState(step: event.step));
    }
  }
}
