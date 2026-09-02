import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:injectable/injectable.dart';
import '../config/app_constants.dart';
import '../routes/app_router.dart';
import '../routes/app_routes.dart';
import 'secure_storage_service.dart';

@lazySingleton
class ApiClient {
  late final Dio _dio;
  final SecureStorageService _storage;

  ApiClient(this._storage, AppRouter router) {
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
      _AuthInterceptor(_storage, router),
      // Was unconditional — serializing every request/response body to a
      // string and printing it on every call (including release builds)
      // adds real synchronous overhead directly in the response path, on
      // every single call a chatty screen like Live Location makes. Debug
      // builds only; release users pay nothing for it.
      if (kDebugMode)
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
  final AppRouter _router;
  _AuthInterceptor(this._storage, this._router);

  // Deduplicates a burst of concurrent requests all failing with 401 at
  // once (e.g. several in-flight calls when the token dies) so the clear +
  // redirect sequence below only actually runs once, not once per request.
  bool _handlingSessionExpiry = false;

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
    // Only treat this as a *session* expiring — not just any 401 — when the
    // failing request actually carried our bearer token. A 401 from a
    // pre-auth endpoint (e.g. wrong OTP/credentials on login/register,
    // where no token was ever attached) isn't a session expiry at all;
    // forcing a redirect to Login there would yank the user out of a flow
    // (like mid-OTP-entry) that's supposed to show its own inline error
    // instead. Leave those to be handled by the caller as today.
    final hadToken = err.requestOptions.headers['Authorization'] != null;
    if (err.response?.statusCode == 401 && hadToken && !_handlingSessionExpiry) {
      _handlingSessionExpiry = true;
      try {
        // SecureStorageService.clearSession() deletes every key
        // TokenStorageService/AuthSessionManager would too (both read/write
        // the exact same flutter_secure_storage keys — see the comment atop
        // SecureStorageService) plus phone/name, so this alone is a
        // complete wipe of cached auth data: access token, refresh token,
        // user id, phone, name, and the auth-status flag.
        await _storage.clearSession();
        // GoRouter's redirect guard only re-runs on an actual navigation
        // event, not automatically when storage changes underneath it — so
        // clearing storage alone wouldn't move the user off whatever screen
        // they're on. Actively navigate to Login; .go() replaces the whole
        // stack rather than pushing on top of it, so the user can't back
        // into screens that required the now-cleared session.
        _router.router.go(AppRoutes.login);
      } finally {
        _handlingSessionExpiry = false;
      }
    }
    handler.next(err);
  }
}
