import 'package:dio/dio.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<void> sendOtp(String phone);
  Future<UserModel> verifyOtp({required String phone, required String otp});
  Future<void> sendEmailOtp(String email);
  Future<void> verifyEmailOtp({required String email, required String otp});
  Future<UserModel> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  });
  Future<UserModel> socialLogin({required String provider, required String token});
  Future<UserModel> getCurrentUser();
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;
  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<void> sendOtp(String phone) async {
    await _dio.post('/auth/otp/send', data: {'phone': phone});
  }

  @override
  Future<UserModel> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final res = await _dio.post('/auth/otp/verify', data: {
      'phone': phone,
      'otp': otp,
    });
    return UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
  }

  @override
  Future<void> sendEmailOtp(String email) async {
    await _dio.post('/auth/email-otp/send', data: {'email': email});
  }

  @override
  Future<void> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    await _dio.post('/auth/email-otp/verify', data: {
      'email': email,
      'otp': otp,
    });
  }

  @override
  Future<UserModel> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
    });
    return UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
  }

  @override
  Future<UserModel> socialLogin({
    required String provider,
    required String token,
  }) async {
    final res = await _dio.post('/auth/social', data: {
      'provider': provider,
      'token': token,
    });
    return UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final res = await _dio.get('/auth/me');
    return UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }
}
