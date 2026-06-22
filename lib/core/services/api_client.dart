import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../config/app_constants.dart';
import 'secure_storage_service.dart';

@lazySingleton
class ApiClient {
  late final Dio _dio;
  final SecureStorageService _storage;

  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _dio.interceptors.addAll([
      _AuthInterceptor(_storage),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => print('[API] $o'),
      ),
    ]);
  }

  Dio get dio => _dio;
}

class _AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;
  _AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAuthToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Token expired — clear session; router guard will redirect to login.
      await _storage.clearSession();
    }
    handler.next(err);
  }
}
