import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Pure token storage — no Firebase dependency.
/// Single source of truth for all auth session data.
class TokenStorageService {
  final FlutterSecureStorage _storage;

  const TokenStorageService(this._storage);

  static const _kAccessToken  = 'sm_access_token';
  static const _kRefreshToken = 'sm_refresh_token';
  static const _kUserId       = 'sm_user_id';
  static const _kAuthStatus   = 'sm_auth_status';  // 'authenticated' | ''

  Future<void> saveAccessToken(String token)  => _storage.write(key: _kAccessToken, value: token);
  Future<String?> getAccessToken()            => _storage.read(key: _kAccessToken);

  Future<void> saveRefreshToken(String token) => _storage.write(key: _kRefreshToken, value: token);
  Future<String?> getRefreshToken()           => _storage.read(key: _kRefreshToken);

  Future<void> saveUserId(String id)          => _storage.write(key: _kUserId, value: id);
  Future<String?> getUserId()                 => _storage.read(key: _kUserId);

  Future<void> setAuthenticated()             => _storage.write(key: _kAuthStatus, value: 'authenticated');

  Future<bool> isAuthenticated() async {
    final token  = await getAccessToken();
    final status = await _storage.read(key: _kAuthStatus);
    return token != null && token.isNotEmpty && status == 'authenticated';
  }

  Future<void> clearAll() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kUserId);
    await _storage.delete(key: _kAuthStatus);
  }
}
