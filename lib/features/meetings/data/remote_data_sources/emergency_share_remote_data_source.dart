import '../../../../core/services/api_client.dart';

abstract class EmergencyShareRemoteDataSource {
  Future<Map<String, dynamic>> getEmergencyShare(String meetingId);
}

class EmergencyShareRemoteDataSourceImpl
    implements EmergencyShareRemoteDataSource {
  final ApiClient _api;
  EmergencyShareRemoteDataSourceImpl(this._api);

  @override
  Future<Map<String, dynamic>> getEmergencyShare(String meetingId) async {
    // ApiClient's LogInterceptor already logs this request/response (debug
    // builds only) — these used to also debugPrint the full raw body a
    // second time, right between the response arriving and it reaching the
    // repository/bloc. debugPrint deliberately throttles large output to
    // avoid Android dropping log lines, so that added real, synchronous
    // delay directly in this screen's poll path. Removed rather than
    // gated: it was pure duplication of what the interceptor already does.
    final res = await _api.dio.get('/v1/meetings/$meetingId/emergency-share');
    return res.data as Map<String, dynamic>;
  }
}
