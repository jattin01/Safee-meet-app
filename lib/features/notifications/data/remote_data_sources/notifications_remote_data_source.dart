import '../../../../core/services/api_client.dart';
import '../models/notifications_page_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<NotificationsPageModel> getNotifications({required int page});
  Future<void> markAsRead(String notificationId);
}

class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  final ApiClient _api;
  NotificationsRemoteDataSourceImpl(this._api);

  @override
  Future<NotificationsPageModel> getNotifications({required int page}) async {
    final response = await _api.dio.get(
      '/v1/notifications',
      queryParameters: {'page': page},
    );
    return NotificationsPageModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _api.dio.post('/v1/notifications/$notificationId/read');
  }
}
