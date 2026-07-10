import '../../../../core/services/api_client.dart';

abstract class EmergencyContactRemoteDataSource {
  Future<List<Map<String, dynamic>>> getContacts();
  Future<Map<String, dynamic>> addContact(Map<String, dynamic> payload);
  Future<void> deleteContact(String contactId);
}

class EmergencyContactRemoteDataSourceImpl implements EmergencyContactRemoteDataSource {
  final ApiClient _api;
  EmergencyContactRemoteDataSourceImpl(this._api);

  @override
  Future<List<Map<String, dynamic>>> getContacts() async {
    // The backend derives the owner from the bearer token — no user id needed.
    final res = await _api.dio.get('/v1/emergency-contact');
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>> addContact(Map<String, dynamic> payload) async {
    final res = await _api.dio.post('/v1/emergency-contact', data: payload);
    final body = res.data as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  @override
  Future<void> deleteContact(String contactId) async {
    await _api.dio.delete('/v1/emergency-contact/$contactId');
  }
}
