import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import '../config/app_constants.dart';

@lazySingleton
class SecureStorageService {
  final FlutterSecureStorage _storage;

  const SecureStorageService(this._storage);

  // ── Token Management ─────────────────────────────────────────────────────

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: AppConstants.kAccessToken, value: token);

  Future<String?> getAccessToken() =>
      _storage.read(key: AppConstants.kAccessToken);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: AppConstants.kRefreshToken, value: token);

  Future<String?> getRefreshToken() =>
      _storage.read(key: AppConstants.kRefreshToken);

  // ── User Session ─────────────────────────────────────────────────────────

  Future<void> saveUserId(String id) =>
      _storage.write(key: AppConstants.kUserId, value: id);

  Future<String?> getUserId() =>
      _storage.read(key: AppConstants.kUserId);

  Future<void> saveUserPhone(String phone) =>
      _storage.write(key: AppConstants.kUserPhone, value: phone);

  Future<String?> getUserPhone() =>
      _storage.read(key: AppConstants.kUserPhone);

  Future<void> saveUserName(String name) =>
      _storage.write(key: 'user_name', value: name);

  Future<String?> getUserName() => _storage.read(key: 'user_name');

  // ── Auth State ───────────────────────────────────────────────────────────

  /// Returns a valid token, refreshing it via Firebase if possible.
  /// Falls back to the locally stored token if Firebase is unavailable.
  Future<String?> getAuthToken() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      try {
        final idToken = await firebaseUser.getIdToken();
        if (idToken != null && idToken.isNotEmpty) {
          await saveAccessToken(idToken);
          return idToken;
        }
      } catch (_) {
        // Network unavailable — fall through to cached token
      }
    }
    return getAccessToken();
  }

  /// Industry-standard check: Firebase Auth persists the session across restarts
  /// and handles token refresh internally. Trusting [currentUser] is sufficient
  /// and avoids false negatives caused by token expiry or network unavailability
  /// at startup. Falls back to stored userId for non-Firebase auth flows (OTP).
  Future<bool> isAuthenticated() async {
    if (FirebaseAuth.instance.currentUser != null) return true;
    final uid = await getUserId();
    return uid != null && uid.isNotEmpty;
  }

  Future<void> clearSession() async {
    await _storage.delete(key: AppConstants.kAccessToken);
    await _storage.delete(key: AppConstants.kRefreshToken);
    await _storage.delete(key: AppConstants.kUserId);
    await _storage.delete(key: AppConstants.kUserPhone);
    await _storage.delete(key: 'user_name');
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // Ignore sign-out failures when clearing local session.
    }
  }
}
