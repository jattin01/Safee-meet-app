import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Pure secure-storage service — no Firebase dependency.
/// Auth state is determined solely by the presence of a Sanctum access token.
/// All keys match TokenStorageService so both services share the same storage slots.
@lazySingleton
class SecureStorageService {
  final FlutterSecureStorage _storage;

  const SecureStorageService(this._storage);

  // Keys must match TokenStorageService constants
  static const _kAccessToken  = 'sm_access_token';
  static const _kRefreshToken = 'sm_refresh_token';
  static const _kUserId       = 'sm_user_id';
  static const _kUserPhone    = 'sm_user_phone';
  static const _kAuthStatus   = 'sm_auth_status';

  // ── Token Management ─────────────────────────────────────────────────────

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _kAccessToken, value: token);

  Future<String?> getAccessToken() =>
      _storage.read(key: _kAccessToken);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _kRefreshToken, value: token);

  Future<String?> getRefreshToken() =>
      _storage.read(key: _kRefreshToken);

  // ── User Session ─────────────────────────────────────────────────────────

  Future<void> saveUserId(String id) =>
      _storage.write(key: _kUserId, value: id);

  Future<String?> getUserId() =>
      _storage.read(key: _kUserId);

  Future<void> saveUserPhone(String phone) =>
      _storage.write(key: _kUserPhone, value: phone);

  Future<String?> getUserPhone() =>
      _storage.read(key: _kUserPhone);

  Future<void> saveUserName(String name) =>
      _storage.write(key: 'sm_user_name', value: name);

  Future<String?> getUserName() => _storage.read(key: 'sm_user_name');

  // ── Auth State ───────────────────────────────────────────────────────────

  Future<String?> getAuthToken() => getAccessToken();

  Future<void> setAuthenticated() =>
      _storage.write(key: _kAuthStatus, value: 'authenticated');

  /// True only if a Sanctum access token AND auth status are both stored.
  Future<bool> isAuthenticated() async {
    final token  = await _storage.read(key: _kAccessToken);
    final status = await _storage.read(key: _kAuthStatus);
    return token != null && token.isNotEmpty && status == 'authenticated';
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kUserId);
    await _storage.delete(key: _kUserPhone);
    await _storage.delete(key: 'sm_user_name');
    await _storage.delete(key: _kAuthStatus);
  }
}
