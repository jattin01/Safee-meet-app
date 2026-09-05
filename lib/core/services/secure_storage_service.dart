import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Pure secure-storage service — no Firebase dependency.
/// Auth state is determined solely by the presence of a Sanctum access token.
/// All keys match TokenStorageService so both services share the same storage slots.
@lazySingleton
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  // Keys must match TokenStorageService constants
  static const _kAccessToken  = 'sm_access_token';
  static const _kRefreshToken = 'sm_refresh_token';
  static const _kUserId       = 'sm_user_id';
  static const _kUserPhone    = 'sm_user_phone';
  static const _kAuthStatus   = 'sm_auth_status';

  // Deliberately NOT cached in memory. This class and TokenStorageService
  // are two separate Dart objects that happen to read/write the same
  // FlutterSecureStorage keys (see the class doc above) — the actual
  // login/session-save path writes through AuthSessionManager ->
  // TokenStorageService, not through this class. An in-memory cache here
  // was tried once and reverted: it got poisoned with a stale "logged
  // out" value read before login (e.g. by the router's auth guard on
  // app start) and then never saw TokenStorageService's writes, so
  // isAuthenticated() kept reporting false — and the post-login redirect
  // to Home — right after a fully successful login. Always read through.

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
  ///
  /// This runs on every single navigation (AppRouter's redirect guard calls
  /// it on every route change, not just at startup), so the two reads are
  /// fired concurrently instead of sequentially — same two platform-channel
  /// round trips either way, same result, just not paying for both back to
  /// back on the navigation-critical path.
  Future<bool> isAuthenticated() async {
    final results = await Future.wait([
      getAccessToken(),
      _storage.read(key: _kAuthStatus),
    ]);
    final token  = results[0];
    final status = results[1];
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

  // ── Background Check Consent ──────────────────────────────────────────────

  static const _kBgConsentAccepted = 'sm_bg_consent_accepted';

  Future<void> saveBgConsentAccepted() =>
      _storage.write(key: _kBgConsentAccepted, value: 'true');

  Future<bool> getBgConsentAccepted() async {
    final val = await _storage.read(key: _kBgConsentAccepted);
    return val == 'true';
  }
}
