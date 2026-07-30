import 'package:flutter/foundation.dart';
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
    final path = '/v1/meetings/$meetingId/emergency-share';
    debugPrint('[EmergencyShare] GET $path');

    final res = await _api.dio.get(path);
    debugPrint('[EmergencyShare] Response (${res.statusCode}): ${res.data}');

    return res.data as Map<String, dynamic>;
  }
}
