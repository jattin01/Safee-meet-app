import '../../../../core/services/api_client.dart';
import '../models/current_subscription_model.dart';
import '../models/subscription_comparison_model.dart';
import '../models/subscription_plan_model.dart';

abstract class SubscriptionRemoteDataSource {
  Future<List<SubscriptionPlanModel>> getPlans();
  Future<Map<String, dynamic>> subscribe({
    required String planSlug,
    required String billingCycle,
    String? stripePaymentMethodId,
  });
  Future<SubscriptionComparisonModel> getComparison();

  /// Returns `null` when the account has no subscription row at all yet
  /// (i.e. it's on the implicit free tier) — the caller maps a 404 to this.
  Future<CurrentSubscriptionModel?> getCurrentSubscription();
}

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  final ApiClient _api;
  SubscriptionRemoteDataSourceImpl(this._api);

  @override
  Future<List<SubscriptionPlanModel>> getPlans() async {
    final response = await _api.dio.get('/v1/subscriptions/plans');
    final data = response.data as List<dynamic>;
    return data
        .map((e) => SubscriptionPlanModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> subscribe({
    required String planSlug,
    required String billingCycle,
    String? stripePaymentMethodId,
  }) async {
    final response = await _api.dio.post('/v1/subscriptions/subscribe', data: {
      'plan_slug': planSlug,
      'billing_cycle': billingCycle,
      if (stripePaymentMethodId != null)
        'stripe_payment_method_id': stripePaymentMethodId,
    });
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<SubscriptionComparisonModel> getComparison() async {
    final response = await _api.dio.get('/v1/subscriptions/comparison');
    return SubscriptionComparisonModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  @override
  Future<CurrentSubscriptionModel?> getCurrentSubscription() async {
    final response = await _api.dio.get('/v1/subscriptions/current');
    final data = response.data;
    if (data == null || (data is Map && data.isEmpty)) return null;
    return CurrentSubscriptionModel.fromJson(data as Map<String, dynamic>);
  }
}
