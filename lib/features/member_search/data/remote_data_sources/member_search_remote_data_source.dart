import '../../../../core/services/api_client.dart';

abstract class MemberSearchRemoteDataSource {
  Future<Map<String, dynamic>> searchByPIN(String pin);
  Future<Map<String, dynamic>> searchByQR(String qrCode);
}

class MemberSearchRemoteDataSourceImpl implements MemberSearchRemoteDataSource {
  final ApiClient _api;
  MemberSearchRemoteDataSourceImpl(this._api);

  @override
  Future<Map<String, dynamic>> searchByPIN(String pin) async {
    final res = await _api.dio.get('/members/search', queryParameters: {'pin': pin});
    return res.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> searchByQR(String qrCode) async {
    final res = await _api.dio.get('/members/qr', queryParameters: {'code': qrCode});
    return res.data as Map<String, dynamic>;
  }
}
