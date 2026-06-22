import '../../../../core/services/api_client.dart';
import '../models/dashboard_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardModel> getDashboard();
  Future<void> toggleLocationSharing(bool enabled);
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final ApiClient _api;
  DashboardRemoteDataSourceImpl(this._api);

  @override
  Future<DashboardModel> getDashboard() async {
    final response = await _api.dio.get('/dashboard');
    return DashboardModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> toggleLocationSharing(bool enabled) async {
    await _api.dio.patch('/user/location-sharing', data: {'enabled': enabled});
  }
}
