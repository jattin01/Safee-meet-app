import 'package:dio/dio.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> register({
    required String provider,
    required String providerToken,
    String? name,
    String? email,
    String? phone,
    String? accountType,
    String? companyName,
    required bool consentAccepted,
  });

  Future<AuthResponseModel> login({
    required String provider,
    required String providerToken,
    String? phone,
  });

  Future<UserModel> getCurrentUser();

  Future<void> logout();

  Future<bool> checkUserExists({
    String? email,
    String? phone,
    String? providerUid,
  });

  /// Returns the OTP's validity window in seconds (`data.expires_in`), if
  /// the backend included one.
  Future<int?> sendOtp(String phone);

  /// Sends the initial phone OTP during registration via the dedicated
  /// registration endpoint (distinct from [sendOtp], which is login-only).
  Future<int?> sendRegisterOtp(String phone);

  /// Resends the phone OTP via the dedicated resend endpoint (distinct from
  /// [sendOtp]'s initial-send endpoint) — used by the "Resend OTP" action on
  /// the OTP verification screen, which stays on that screen throughout.
  Future<int?> resendOtp(String phone);

  /// Verifies the OTP against the backend (new SMS provider) and returns the
  /// Firebase custom token the backend minted for this phone's uid — the
  /// caller then does FirebaseAuth.signInWithCustomToken(token) with it.
  Future<String> verifyOtp({required String phone, required String otp});

  Future<void> sendEmailOtp(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;
  const AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<AuthResponseModel> register({
    required String provider,
    required String providerToken,
    String? name,
    String? email,
    String? phone,
    String? accountType,
    String? companyName,
    required bool consentAccepted,
  }) async {
    final res = await _dio.post('/v1/auth/register', data: {
      'provider':                provider,
      'providerToken':           providerToken,
      if (name != null)        'name':        name,
      if (email != null)       'email':       email,
      if (phone != null)       'phone':       phone,
      if (accountType != null) 'accountType': accountType,
      if (companyName != null) 'companyName': companyName,
      'consentAccepted':         consentAccepted,
    });
    return AuthResponseModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<AuthResponseModel> login({
    required String provider,
    required String providerToken,
    String? phone,
  }) async {
    final res = await _dio.post('/v1/auth/login', data: {
      'provider':         provider,
      'providerToken':    providerToken,
      if (phone != null) 'phone': phone,
      'loginType':        'social',
    });
    return AuthResponseModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final res = await _dio.get('/v1/auth/me');
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    await _dio.post('/v1/auth/logout');
  }

  @override
  Future<bool> checkUserExists({
    String? email,
    String? phone,
    String? providerUid,
  }) async {
    final res = await _dio.post('/v1/auth/check-user-exists', data: {
      if (email != null)       'email':       email,
      if (phone != null)       'phone':       phone,
      if (providerUid != null) 'providerUid': providerUid,
    });
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return data['exists'] as bool;
  }

  @override
  Future<int?> sendOtp(String phone) async {
    final res = await _dio.post('/v1/auth/send-otp', data: {'phone': phone});
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    return data?['expires_in'] as int?;
  }

  @override
  Future<int?> sendRegisterOtp(String phone) async {
    final res = await _dio.post('/v1/auth/send-register-otp', data: {'phone': phone});
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    return data?['expires_in'] as int?;
  }

  @override
  Future<int?> resendOtp(String phone) async {
    final res = await _dio.post('/v1/auth/resend-otp', data: {'phone': phone});
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    return data?['expires_in'] as int?;
  }

  @override
  Future<String> verifyOtp({required String phone, required String otp}) async {
    final res = await _dio.post('/v1/auth/verify-otp', data: {'phone': phone, 'otp': otp});
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return data['firebaseCustomToken'] as String;
  }

  @override
  Future<void> sendEmailOtp(String email) async {
    await _dio.post('/v1/auth/email-otp/send', data: {'email': email});
  }

  Future<String?> sendEmailOtpWithDevCode(String email) async {
    final res = await _dio.post('/v1/auth/email-otp/send', data: {'email': email});
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return data['dev_otp'] as String?; // only present in local env
  }

  Future<void> verifyEmailOtp(String email, String otp) async {
    await _dio.post('/v1/auth/email-otp/verify', data: {'email': email, 'otp': otp});
  }
}
