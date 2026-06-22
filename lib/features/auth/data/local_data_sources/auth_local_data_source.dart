import '../../../../core/services/secure_storage_service.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> saveTokens({required String access, required String refresh});
  Future<void> clearAll();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorageService _storage;

  AuthLocalDataSourceImpl(this._storage);

  @override
  Future<void> cacheUser(UserModel user) async {
    await _storage.saveUserId(user.id);
    // Persist serialised user alongside tokens (not secret but convenient here)
    // In production you'd use Hive for non-sensitive cached data.
  }

  @override
  Future<UserModel?> getCachedUser() async {
    // Implemented via profile cache. Stub returning null; data arrives via API.
    return null;
  }

  @override
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _storage.saveAccessToken(access);
    await _storage.saveRefreshToken(refresh);
  }

  @override
  Future<void> clearAll() => _storage.clearSession();
}
