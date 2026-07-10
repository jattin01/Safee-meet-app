import '../../../../core/services/api_client.dart';

abstract class MemberSearchRemoteDataSource {
  Future<Map<String, dynamic>> searchByPIN(String pin);
  Future<Map<String, dynamic>> searchByQR(String qrCode);

  /// Members the current user has previously searched for, most recent
  /// first — tracked server-side so the list survives app reinstalls.
  Future<List<Map<String, dynamic>>> getRecentSearches();
}

class MemberSearchRemoteDataSourceImpl implements MemberSearchRemoteDataSource {
  final ApiClient _api;
  MemberSearchRemoteDataSourceImpl(this._api);

  @override
  Future<Map<String, dynamic>> searchByPIN(String pin) async {
    final res = await _api.dio.get('/v1/members/search', queryParameters: {'pin': pin});
    return (res.data['data'] ?? res.data) as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> searchByQR(String qrCode) async {
    final res = await _api.dio.get('/v1/members/qr', queryParameters: {'code': qrCode});
    return (res.data['data'] ?? res.data) as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentSearches() async {
    final res = await _api.dio.get('/v1/members/recent-searches');
    final data = (res.data['data'] ?? res.data) as List;
    return data.map((e) => e as Map<String, dynamic>).toList();
  }
}
