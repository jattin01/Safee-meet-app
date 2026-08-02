import '../../../../core/services/hive_service.dart';
import '../models/current_subscription_model.dart';

/// A cache hit for the current-subscription lookup. [json] itself may be
/// null — that's a valid, confirmed-by-the-server "no active subscription"
/// result, distinct from "not cached yet / expired" (which the data source
/// signals by returning `null` for the whole entry instead of this wrapper).
class CurrentSubscriptionCacheEntry {
  final Map<String, dynamic>? json;
  const CurrentSubscriptionCacheEntry(this.json);
}

abstract class SubscriptionLocalDataSource {
  Future<CurrentSubscriptionCacheEntry?> getCachedCurrentSubscription();
  Future<void> cacheCurrentSubscription(CurrentSubscriptionModel? model);
  Future<void> clearCurrentSubscriptionCache();
}

class SubscriptionLocalDataSourceImpl implements SubscriptionLocalDataSource {
  final HiveService _hive;
  SubscriptionLocalDataSourceImpl(this._hive);

  static const String _cacheKey = 'current_subscription';

  // Cache expires quickly on its own even if nothing ever invalidates it
  // explicitly, satisfying "refresh on app relaunch if cache expired".
  static const Duration _ttl = Duration(minutes: 15);

  @override
  Future<CurrentSubscriptionCacheEntry?> getCachedCurrentSubscription() async {
    final raw = _hive.cacheBox.get(_cacheKey);
    if (raw is! Map) return null;

    final cachedAt = DateTime.tryParse(raw['cached_at'] as String? ?? '');
    if (cachedAt == null || DateTime.now().difference(cachedAt) > _ttl) {
      return null;
    }

    final data = raw['data'];
    return CurrentSubscriptionCacheEntry(
      data == null ? null : Map<String, dynamic>.from(data as Map),
    );
  }

  @override
  Future<void> cacheCurrentSubscription(CurrentSubscriptionModel? model) {
    return _hive.cacheBox.put(_cacheKey, {
      'data': model?.toJson(),
      'cached_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> clearCurrentSubscriptionCache() =>
      _hive.cacheBox.delete(_cacheKey);
}
