import 'package:dio/dio.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> register({
    required String provider,
    required String providerToken,
    String? name,
    String? email,
    String? accountType,
    String? companyName,
    required bool consentAccepted,
  });

  Future<AuthResponseModel> login({
    required String provider,
    required String providerToken,
  });

  Future<UserModel> getCurrentUser();

  Future<void> logout();

  Future<bool> checkUserExists({
    String? email,
    String? phone,
    String? providerUid,
  });

  Future<void> sendOtp(String phone);
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
    String? accountType,
    String? companyName,
    required bool consentAccepted,
  }) async {
    final res = await _dio.post('/v1/auth/register', data: {
      'provider':                provider,
      'providerToken':           providerToken,
      if (name != null)        'name':        name,
      if (email != null)       'email':       email,
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
  }) async {
    final res = await _dio.post('/v1/auth/login', data: {
      'provider':      provider,
      'providerToken': providerToken,
      'loginType':     'social',
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
  Future<void> sendOtp(String phone) async {
    await _dio.post('/v1/auth/verify-phone', data: {'phone': phone, 'providerToken': ''});
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
