import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/services/api_client.dart';

abstract class VerificationRemoteDataSource {
  Future<Map<String, dynamic>> getVerificationStatus();
  Future<Map<String, dynamic>> submitVerification({
    required String userId,
    required File faceIdImage,
    required File nationalIdFrontImage,
    required File nationalIdBackImage,
    required String nationalIdNumber,
    required String nationalIdCountry,
  });
  Future<Map<String, dynamic>> getVerificationProgress();
}

class VerificationRemoteDataSourceImpl implements VerificationRemoteDataSource {
  final ApiClient _api;
  VerificationRemoteDataSourceImpl(this._api);

  @override
  Future<Map<String, dynamic>> getVerificationStatus() async {
    final res = await _api.dio.get('/v1/auth/me');
    final body = res.data as Map<String, dynamic>;
    return body['data']?['user'] as Map<String, dynamic>? ?? const {};
  }

  @override
  Future<Map<String, dynamic>> submitVerification({
    required String userId,
    required File faceIdImage,
    required File nationalIdFrontImage,
    required File nationalIdBackImage,
    required String nationalIdNumber,
    required String nationalIdCountry,
  }) async {
    final formData = FormData.fromMap({
      'user_id': userId,
      'face_id_image':
          await MultipartFile.fromFile(faceIdImage.path, filename: 'face_id.jpg'),
      'national_id_front_image': await MultipartFile.fromFile(
          nationalIdFrontImage.path,
          filename: 'national_id_front.jpg'),
      'national_id_back_image': await MultipartFile.fromFile(
          nationalIdBackImage.path,
          filename: 'national_id_back.jpg'),
      'national_id_number': nationalIdNumber,
      'national_id_country': nationalIdCountry,
    });
    final res = await _api.dio.post('/v1/verification/submit', data: formData);
    return res.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getVerificationProgress() async {
    final res = await _api.dio.get('/v1/verification/progress');
    return res.data as Map<String, dynamic>;
  }
}
