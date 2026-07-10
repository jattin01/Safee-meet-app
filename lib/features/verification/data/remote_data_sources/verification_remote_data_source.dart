import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/services/api_client.dart';

abstract class VerificationRemoteDataSource {
  Future<Map<String, dynamic>> getVerificationStatus();
  Future<void> uploadIdDocument({required File front, required File back});
  Future<void> uploadSelfie(File selfie);
  Future<Map<String, dynamic>> getVerificationProgress();
}

class VerificationRemoteDataSourceImpl implements VerificationRemoteDataSource {
  final ApiClient _api;
  VerificationRemoteDataSourceImpl(this._api);

  @override
  Future<Map<String, dynamic>> getVerificationStatus() async {
    final res = await _api.dio.get('/v1/verification/status');
    return res.data as Map<String, dynamic>;
  }

  @override
  Future<void> uploadIdDocument(
      {required File front, required File back}) async {
    final formData = FormData.fromMap({
      'front':
          await MultipartFile.fromFile(front.path, filename: 'id_front.jpg'),
      'back': await MultipartFile.fromFile(back.path, filename: 'id_back.jpg'),
    });
    await _api.dio.post('/v1/verification/id', data: formData);
  }

  @override
  Future<void> uploadSelfie(File selfie) async {
    final formData = FormData.fromMap({
      'selfie':
          await MultipartFile.fromFile(selfie.path, filename: 'selfie.jpg'),
    });
    await _api.dio.post('/v1/verification/selfie', data: formData);
  }

  @override
  Future<Map<String, dynamic>> getVerificationProgress() async {
    final res = await _api.dio.get('/v1/verification/progress');
    return res.data as Map<String, dynamic>;
  }
}
