import '../../../../core/services/api_client.dart';

abstract class VerificationRemoteDataSource {
  Future<Map<String, dynamic>> getVerificationStatus();

  /// Asks our backend to open a Didit verification session (backend calls
  /// Didit's `POST /v3/session/` with the workflow_id + secret API key,
  /// neither of which ever reach the client) and returns the short-lived
  /// session token the SDK needs to launch its capture UI.
  Future<Map<String, dynamic>> createDiditSession();
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
  Future<Map<String, dynamic>> createDiditSession() async {
    final res = await _api.dio.post('/v1/verification/didit/start');
    final body = res.data as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>? ?? body;
  }
}
