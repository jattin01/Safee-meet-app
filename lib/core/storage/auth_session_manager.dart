import 'token_storage_service.dart';

/// High-level session manager used across the app.
/// Coordinates token storage; never talks to Firebase directly.
class AuthSessionManager {
  final TokenStorageService _tokenStorage;

  const AuthSessionManager(this._tokenStorage);

  Future<bool> isAuthenticated() => _tokenStorage.isAuthenticated();

  Future<String?> getAccessToken() => _tokenStorage.getAccessToken();

  Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    required String userId,
  }) async {
    await Future.wait([
      _tokenStorage.saveAccessToken(accessToken),
      _tokenStorage.saveUserId(userId),
      if (refreshToken != null) _tokenStorage.saveRefreshToken(refreshToken),
      _tokenStorage.setAuthenticated(),
    ]);
  }

  Future<void> clearSession() => _tokenStorage.clearAll();
}
